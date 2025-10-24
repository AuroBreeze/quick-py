local state = require('quick-py.state')
local env = require('quick-py.env')
local util = require('quick-py.util')

local M = {}

local function run_in_native_terminal(cmd)
  vim.cmd('botright split | terminal')
  local chan = vim.b.terminal_job_id
  if not chan then return false end
  vim.defer_fn(function()
    vim.fn.chansend(chan, cmd .. '\r')
  end, 100)
  return true
end

local function run_in_betterterm(cmd)
  local ok, betterTerm = pcall(require, 'betterTerm')
  if not ok then return false end
  local cfg = (state.config and state.config.betterterm) or {}
  local idx = cfg.index or 0
  local delay = cfg.send_delay or 200
  local focus = (cfg.focus_on_run ~= false)
  local open_first = (cfg.open_if_closed ~= false)
  if open_first or focus then pcall(betterTerm.open, idx) end
  vim.defer_fn(function()
    local ok_send = pcall(betterTerm.send, cmd .. '\r', idx)
    if not ok_send then
      if not run_in_native_terminal(cmd) then
        vim.notify('[Quick-py] 无法发送命令到终端', vim.log.levels.ERROR)
      end
    end
  end, delay)
  return true
end

local function run_cmd(cmd)
  if not run_in_betterterm(cmd) then
    if not run_in_native_terminal(cmd) then
      vim.notify('[Quick-py] 无法运行命令：尝试打开内置终端失败', vim.log.levels.ERROR)
    end
  end
end

-- Build pip install command using current venv python if available
local function build_pip_install_cmd(pkgs)
  local _ = env.get_venv() -- ensure python_path is set
  local py = (state.config and state.config.python_path) or 'python'
  local args = {}
  for _, p in ipairs(pkgs) do table.insert(args, vim.fn.shellescape(p)) end
  return table.concat({ vim.fn.shellescape(py), '-m', 'pip', 'install', table.concat(args, ' ') }, ' ')
end

local function build_pip_install_file_cmd(file)
  local _ = env.get_venv()
  local py = (state.config and state.config.python_path) or 'python'
  return table.concat({ vim.fn.shellescape(py), '-m', 'pip', 'install', '-r', vim.fn.shellescape(file) }, ' ')
end

local function read_lines(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then return {} end
  return lines
end

local function parse_packages(lines)
  local pkgs = {}
  for _, ln in ipairs(lines) do
    local s = vim.trim(ln)
    if s ~= '' and not s:match('^#') then
      table.insert(pkgs, s)
    end
  end
  return pkgs
end

function M.PickAndInstall()
  local ok_t, telescope = pcall(require, 'telescope')
  if not ok_t then
    vim.notify('[Quick-py] 需要安装 nvim-telescope/telescope.nvim', vim.log.levels.ERROR)
    return
  end
  local ok_p, scandir = pcall(require, 'plenary.scandir')
  if not ok_p then
    vim.notify('[Quick-py] 需要安装 nvim-lua/plenary.nvim', vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local files = {}
  local cfg = (state.config and state.config.requirements) or {}
  local depth_down = tonumber(cfg.depth_down) or 6
  local depth_up = tonumber(cfg.depth_up) or 0
  local include_all_txt = (cfg.include_all_txt ~= false)
  local excludes = {}
  for _, name in ipairs(cfg.excludes or {}) do excludes[name] = true end

  local function is_excluded(path)
    local p = util.normalize_path(path)
    for seg in string.gmatch(p, "[^/\\]+") do
      if excludes[seg] then return true end
    end
    return false
  end

  local function scan_once(dir)
    scandir.scan_dir(dir, {
      hidden = false,
      add_dirs = false,
      depth = depth_down,
      respect_gitignore = true,
      on_insert = function(entry)
        if is_excluded(entry) then return end
        local low = entry:lower()
        if low:match('requirements.*%.txt$') or (include_all_txt and low:match('%.txt$')) then
          table.insert(files, util.normalize_path(entry))
        end
      end,
    })
  end

  -- 扫描 cwd 以及向上目录（最多 depth_up 层）
  local dir = cwd
  local up = 0
  while dir and dir ~= '' do
    scan_once(dir)
    if up >= depth_up then break end
    local parent = vim.fn.fnamemodify(dir, ':h')
    if parent == dir or parent == '' then break end
    dir = parent
    up = up + 1
  end

  -- 去重
  local uniq = {}
  local out = {}
  for _, f in ipairs(files) do
    if not uniq[f] then uniq[f] = true table.insert(out, f) end
  end
  files = out

  if #files == 0 then
    vim.notify('[Quick-py] 未找到 requirements*.txt（或 *.txt）文件', vim.log.levels.WARN)
    return
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local previewers = require('telescope.previewers')
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  pickers.new({}, {
    prompt_title = '选择 requirements 文件',
    finder = finders.new_table({ results = files }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.vim_buffer_cat.new({}),
    attach_mappings = function(prompt_bufnr, map)
      local function select_file()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not entry or not entry[1] then return end
        local path = entry[1]
        local pkgs = parse_packages(read_lines(path))
        if #pkgs == 0 then
          vim.notify('[Quick-py] 文件中未找到可安装的包', vim.log.levels.WARN)
          return
        end
        local INSTALL_ALL = '[Install ALL from this file]'
        local results = { INSTALL_ALL }
        for _, p in ipairs(pkgs) do table.insert(results, p) end
        pickers.new({}, {
          prompt_title = '选择要安装的包',
          finder = finders.new_table({ results = results }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(buf2, _)
            actions.select_default:replace(function()
              local sel = action_state.get_selected_entry()
              local chosen = {}
              local ok_picker, picker = pcall(action_state.get_current_picker, buf2)
              if ok_picker and picker and picker.get_multi_selection then
                local multi = picker:get_multi_selection()
                if multi and #multi > 0 then
                  for _, e in ipairs(multi) do table.insert(chosen, e[1]) end
                end
              end
              if #chosen == 0 and sel and sel[1] then
                table.insert(chosen, sel[1])
              end
              actions.close(buf2)
              if #chosen == 0 then return end
              -- 如果选择了整文件安装项，执行 -r <file>
              local has_all = false
              for _, c in ipairs(chosen) do if c == INSTALL_ALL then has_all = true break end end
              if has_all then
                run_cmd(build_pip_install_file_cmd(path))
              else
                run_cmd(build_pip_install_cmd(chosen))
              end
            end)
            return true
          end,
        }):find()
      end
      actions.select_default:replace(select_file)
      return true
    end,
  }):find()
end

return M

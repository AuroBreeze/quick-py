local state = require('quick-py.state')
local env = require('quick-py.env')
local lsp = require('quick-py.lsp')
local M = {}

local function run_in_betterterm(cmd)
  local ok, betterTerm = pcall(require, 'betterTerm')
  if not ok then return false end
  local cfg = state.config.betterterm or {}
  local idx = cfg.index or 0
  local delay = cfg.send_delay or 200
  local focus = (cfg.focus_on_run ~= false)
  local open_first = (cfg.open_if_closed ~= false)
  if open_first then pcall(betterTerm.open, idx) end
  vim.defer_fn(function()
    local ok_send, err = pcall(betterTerm.send, cmd .. '\r', idx)
    if not ok_send then
      vim.notify('[Quick-py] 发送到 betterTerm 失败，回退到普通执行: ' .. tostring(err), vim.log.levels.WARN)
      vim.cmd('!' .. cmd)
      return
    end
    if focus then pcall(betterTerm.open, idx) end
  end, delay)
  return true
end

function M.setup()
  vim.api.nvim_create_user_command('RunPython', function()
    if not vim.env.VIRTUAL_ENV then
      vim.notify('[Quick-py] 未找到虚拟环境', vim.log.levels.ERROR)
      return
    end
    local cmd
    if state.config.runserver_cmd then
      cmd = state.config.runserver_cmd
    else
      cmd = 'python' .. ' ' .. vim.fn.shellescape(vim.fn.expand('%:p'))
    end
    if not run_in_betterterm(cmd) then
      vim.cmd('!' .. cmd)
    end
  end, { desc = 'Run current Python file in virtualenv' })

  vim.api.nvim_create_user_command('SetRunPythonCmd', function(opts)
    state.config.runserver_cmd = opts.args
    vim.notify('[Quick-py] 设置运行命令: ' .. opts.args, vim.log.levels.INFO)
  end, { nargs = 1, desc = '设置自定义 Python 运行命令' })

  vim.api.nvim_create_user_command('SetPyKeymap', function(opts)
    local args = vim.split(opts.args, ' ', { trimempty = true })
    if #args < 2 then
      vim.notify('[Quick-py] 参数不足，格式: SetPyKeymap <name> <key> [cmd]', vim.log.levels.ERROR)
      return
    end
    local name = args[1]
    local key = args[2]
    local cmd = args[3] or state.config.keymaps[name][2]
    state.config.keymaps[name] = { key, cmd, { desc = state.config.keymaps[name][3].desc } }
    if type(cmd) == 'string' or type(cmd) == 'function' then
      vim.keymap.set('n', key, cmd, { desc = state.config.keymaps[name][3].desc })
    end
    vim.notify('[Quick-py] 已更新键位 ' .. name .. ' 为 ' .. key, vim.log.levels.INFO)
  end, { nargs = '*', desc = '设置 Quick-py 键位映射' })

  vim.api.nvim_create_user_command('QuickPyAutoActivate', function(opts)
    local arg = (opts.args or ''):lower()
    if arg == 'on' or arg == 'enable' then
      state.config.auto_activate_terminal = true
    elseif arg == 'off' or arg == 'disable' then
      state.config.auto_activate_terminal = false
    else
      state.config.auto_activate_terminal = not state.config.auto_activate_terminal
    end
    local state_text = state.config.auto_activate_terminal and '开启' or '关闭'
    vim.notify('[Quick-py] 终端自动激活已' .. state_text, vim.log.levels.INFO)
  end, { nargs = '?', complete = function() return { 'on', 'off', 'toggle' } end, desc = '控制终端自动激活: on/off/toggle（无参=toggle）' })
end

return M

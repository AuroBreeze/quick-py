local state = require('quick-py.state')
local M = {}

function M.find_venv_downward(base_dir, current_depth, max_depth)
  if current_depth > max_depth then return nil, nil end
  local subdirs = vim.fn.globpath(base_dir, '*/', 0, 1)
  for _, sub in ipairs(subdirs) do
    local dir = sub:gsub('[\\/]+$', '')
    for _, name in ipairs(state.config.venv_names or {}) do
      local cand = dir .. '/' .. name
      if vim.fn.isdirectory(cand) == 1 then
        return dir, cand
      end
    end
    local found_root, found_venv = M.find_venv_downward(dir, current_depth + 1, max_depth)
    if found_root then return found_root, found_venv end
  end
  return nil, nil
end

function M.find_local_venv(start_dir)
  local dir = start_dir or vim.fn.expand('%:p:h')
  if dir == '' then dir = vim.fn.getcwd() end
  local up_steps = 0
  while dir and dir ~= '' do
    for _, name in ipairs(state.config.venv_names or {}) do
      local cand = dir .. '/' .. name
      if vim.fn.isdirectory(cand) == 1 then
        return dir, cand
      end
    end
    if state.config.max_down_depth and state.config.max_down_depth > 0 then
      local droot, dvenv = M.find_venv_downward(dir, 1, state.config.max_down_depth)
      if droot then return droot, dvenv end
    end
    local parent = vim.fn.fnamemodify(dir, ':h')
    if parent == dir or parent == '' then break end
    dir = parent
    up_steps = up_steps + 1
    if state.config.max_up_depth and up_steps >= state.config.max_up_depth then break end
  end
  return nil, nil
end

function M.find_up_file(start_dir, targets)
  local dir = start_dir or vim.fn.getcwd()
  if dir == '' then dir = vim.fn.getcwd() end
  local up_steps = 0
  while dir and dir ~= '' do
    for _, f in ipairs(targets) do
      local cand = dir .. '/' .. f
      if vim.fn.filereadable(cand) == 1 then
        return dir, cand
      end
    end
    local parent = vim.fn.fnamemodify(dir, ':h')
    if parent == dir or parent == '' then break end
    dir = parent
    up_steps = up_steps + 1
    if state.config.max_up_depth and up_steps >= state.config.max_up_depth then break end
  end
  return nil, nil
end

function M.system_list_in_dir(cmd, dir)
  local is_win = vim.fn.has('win32') == 1
  local full_cmd
  if is_win then
    full_cmd = string.format('cmd /C "(cd /d "%s") && %s"', dir, cmd)
  else
    full_cmd = string.format('sh -c "cd \"%s\" && %s"', dir, cmd)
  end
  local ok, out = pcall(vim.fn.systemlist, full_cmd)
  if not ok then return {} end
  return out
end

return M

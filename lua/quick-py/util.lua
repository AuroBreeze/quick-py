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

-- 规范化路径：统一分隔符并移除末尾分隔符
function M.normalize_path(p)
  if not p or p == '' then return p end
  local is_win = vim.fn.has('win32') == 1
  if is_win then
    p = p:gsub('/', '\\')
    p = p:gsub('\\+$', '')
  else
    p = p:gsub('\\', '/')
    p = p:gsub('/+$', '')
  end
  return p
end

-- 简单的路径拼接（不访问文件系统）
function M.path_join(a, b)
  if not a or a == '' then return b end
  if not b or b == '' then return a end
  local is_win = vim.fn.has('win32') == 1
  local sep = is_win and '\\' or '/'
  a = M.normalize_path(a)
  b = b:gsub('^[\\/]+', '')
  return a .. sep .. b
end

-- 将目录前置到 PATH（若未存在），避免重复
function M.prepend_env_path_once(dir)
  if not dir or dir == '' then return false end
  local is_win = vim.fn.has('win32') == 1
  local sep = is_win and ';' or ':'
  local current = vim.env.PATH or ''
  local normdir = M.normalize_path(dir)
  -- 拆分 PATH 并做规范化比较
  local exists = false
  for entry in string.gmatch(current, "[^" .. sep .. "]+") do
    local n = M.normalize_path(entry)
    if is_win then
      if n:lower() == normdir:lower() then exists = true break end
    else
      if n == normdir then exists = true break end
    end
  end
  if exists then return false end
  if current == '' then
    vim.env.PATH = normdir
  else
    vim.env.PATH = normdir .. sep .. current
  end
  return true
end

return M

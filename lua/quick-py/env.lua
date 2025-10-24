local state = require('quick-py.state')
local util = require('quick-py.util')
local M = {}

local function detect_poetry_env(start_dir)
  if vim.fn.executable('poetry') ~= 1 then return nil, nil end
  local root = select(1, util.find_up_file(start_dir, { 'pyproject.toml' }))
  if not root then return nil, nil end
  local lines = util.system_list_in_dir('poetry -C . env info -p', root)
  if #lines > 0 and lines[1] ~= '' then
    return root, lines[1]
  end
  return nil, nil
end

local function detect_pipenv_env(start_dir)
  if vim.fn.executable('pipenv') ~= 1 then return nil, nil end
  local root = select(1, util.find_up_file(start_dir, { 'Pipfile' }))
  if not root then return nil, nil end
  local lines = util.system_list_in_dir('pipenv --venv', root)
  if #lines > 0 and lines[1] ~= '' then
    return root, lines[1]
  end
  return nil, nil
end

local function detect_uv_env(start_dir)
  if vim.fn.executable('uv') ~= 1 then return nil, nil end
  -- uv 通常使用 pyproject.toml 并在项目根生成 .venv
  local root = select(1, util.find_up_file(start_dir, { 'pyproject.toml' }))
  if not root then return nil, nil end
  local found_root, venv = util.find_local_venv(root)
  if found_root and venv then return found_root, venv end
  return nil, nil
end

local function detect_pdm_env(start_dir)
  if vim.fn.executable('pdm') ~= 1 then return nil, nil end
  -- pdm 也通常通过 pyproject.toml 并默认使用本地 .venv（如启用 venv backend）
  local root = select(1, util.find_up_file(start_dir, { 'pyproject.toml' }))
  if not root then return nil, nil end
  local found_root, venv = util.find_local_venv(root)
  if found_root and venv then return found_root, venv end
  return nil, nil
end

local function detect_conda_env(_)
  local prefix = vim.env.CONDA_PREFIX
  if prefix and prefix ~= '' then
    return vim.fn.getcwd(), prefix
  end
  return nil, nil
end

function M.get_venv()
  if state.cached_venv_dir and vim.fn.executable(state.config.python_path) == 1 then
    return state.cached_venv_dir
  end
  local buf_dir = vim.fn.expand('%:p:h')
  local root_dir, venv = nil, nil
  local tried = {}
  for _, kind in ipairs(state.config.env_detection or { 'local', 'poetry', 'pipenv', 'conda' }) do
    if kind == 'local' then
      root_dir, venv = util.find_local_venv(buf_dir)
    elseif kind == 'poetry' then
      root_dir, venv = detect_poetry_env(buf_dir)
    elseif kind == 'pipenv' then
      root_dir, venv = detect_pipenv_env(buf_dir)
    elseif kind == 'uv' then
      root_dir, venv = detect_uv_env(buf_dir)
    elseif kind == 'pdm' then
      root_dir, venv = detect_pdm_env(buf_dir)
    elseif kind == 'conda' then
      root_dir, venv = detect_conda_env(buf_dir)
    end
    table.insert(tried, kind)
    if root_dir and venv then
      state.env_type = kind
      break
    end
  end
  if not root_dir then
    vim.notify("[Quick-py] 未找到可用虚拟环境 (tried: " .. table.concat(tried, ',') .. ")", vim.log.levels.WARN)
    return nil
  end

  venv = vim.fn.resolve(venv)
  venv = vim.fn.simplify(venv)
  local is_win = vim.fn.has('win32') == 1
  if is_win then venv = venv:gsub('/', '\\'):gsub('\\+$', '') else venv = venv:gsub('\\', '/'):gsub('/+$', '') end

  if state.cached_venv_dir and state.cached_venv_dir ~= venv then
    vim.lsp.stop_client(vim.lsp.get_active_clients({ name = 'pyright' }))
    state.lsp_started = false
  end

  local pybin = is_win and (venv .. '\\Scripts\\python.exe') or (venv .. '/bin/python')
  if vim.fn.executable(pybin) == 0 then
    vim.notify("[Quick-py] Python 不可执行: " .. pybin, vim.log.levels.ERROR)
    return nil
  end

  vim.env.VIRTUAL_ENV = venv
  local scripts_dir = is_win and (venv .. '\\Scripts') or (venv .. '/bin')
  pcall(function()
    util.prepend_env_path_once(scripts_dir)
  end)
  state.config.python_path = pybin
  vim.g.python3_host_prog = pybin
  state.cached_root = root_dir
  state.cached_venv_dir = venv
  vim.notify("[Quick-py] 已找到虚拟环境(" .. (state.env_type or 'local') .. "): " .. venv, vim.log.levels.INFO)
  return venv
end

return M

local M = {}

-- Resolve health reporter (Neovim 0.9: require('health'); 0.10+: vim.health)
local function get_health()
  local ok, mod = pcall(require, 'health')
  if ok and mod then return mod end
  if vim and vim.health then return vim.health end
  -- Fallback shim
  local stub = {}
  local levels = { 'start', 'ok', 'warn', 'error', 'info' }
  for _, k in ipairs(levels) do stub[k] = function(_) end end
  return stub
end

local function is_windows()
  return (vim.fn.has('win32') == 1) or (vim.fn.has('win64') == 1)
end

local function exists_exe(bin)
  return vim.fn.executable(bin) == 1
end

local function check_python(health)
  health.start('Python runtime')
  local candidates = is_windows() and { 'python', 'python3' } or { 'python3', 'python' }

  -- Check from VIRTUAL_ENV first
  local venv = vim.env.VIRTUAL_ENV
  if venv and venv ~= '' then
    local py = is_windows() and (venv .. '\\Scripts\\python.exe') or (venv .. '/bin/python')
    if vim.fn.filereadable(py) == 1 then
      if vim.fn.executable(py) == 1 then
        health.ok('Python found in virtualenv: ' .. py)
        return py
      else
        health.warn('Python in virtualenv is not executable: ' .. py)
      end
    else
      health.warn('VIRTUAL_ENV set but python not found at: ' .. py)
    end
  else
    health.info('VIRTUAL_ENV not set')
  end

  for _, bin in ipairs(candidates) do
    if exists_exe(bin) then
      health.ok('System Python found: ' .. bin)
      return bin
    end
  end
  health.error('No Python executable found (checked: ' .. table.concat(candidates, ', ') .. ')')
  return nil
end

local function check_pyright(health)
  health.start('Pyright language server')
  local names = is_windows() and { 'pyright-langserver.exe', 'pyright-langserver' } or { 'pyright-langserver' }

  -- Try venv local server if VIRTUAL_ENV is set
  local venv = vim.env.VIRTUAL_ENV
  if venv and venv ~= '' then
    local server = is_windows() and (venv .. '\\Scripts\\pyright-langserver.exe') or (venv .. '/bin/pyright-langserver')
    if vim.fn.filereadable(server) == 1 and vim.fn.executable(server) == 1 then
      health.ok('Pyright found in virtualenv: ' .. server)
      return true
    end
  end

  for _, n in ipairs(names) do
    if exists_exe(n) then
      health.ok('Pyright found in PATH: ' .. n)
      return true
    end
  end
  health.warn('Pyright not found. Install with: npm i -g pyright 或在虚拟环境中安装')
  return false
end

local function check_optional_plugins(health)
  health.start('Optional plugins')
  do
    local ok = pcall(require, 'betterTerm')
    if ok then
      health.ok('betterTerm detected')
    else
      health.info('betterTerm not found (optional)')
    end
  end
  do
    local ok = pcall(require, 'project_nvim')
    if ok then
      health.ok('project.nvim detected')
    else
      health.info('project.nvim not found (optional)')
    end
  end
end

local function check_quick_py_config(health)
  health.start('quick-py configuration')
  local ok, qp = pcall(require, 'quick-py')
  if not ok then
    health.error('Failed to require("quick-py"). Make sure plugin is installed and runtimepath is correct.')
    return
  end
  if type(qp.setup) == 'function' then
    health.ok('quick-py loaded')
  else
    health.warn('quick-py loaded but setup() not found')
  end
  -- Report env hints
  if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= '' then
    health.ok('VIRTUAL_ENV=' .. vim.env.VIRTUAL_ENV)
  else
    health.info('No active virtualenv (VIRTUAL_ENV is empty)')
  end
end

function M.check()
  local health = get_health()
  check_quick_py_config(health)
  check_python(health)
  check_pyright(health)
  check_optional_plugins(health)
  -- Shell-specific hints
  health.start('Shell integration hints')
  local shell = vim.o.shell or ''
  if is_windows() then
    if shell:lower():find('powershell') or shell:lower():find('pwsh') then
      health.info('Windows PowerShell detected: activation uses Activate.ps1')
    else
      health.info('Windows cmd detected: activation uses activate.bat')
    end
  else
    health.info('Unix-like shell detected: activation uses "source <venv>/bin/activate"')
  end
end

return M

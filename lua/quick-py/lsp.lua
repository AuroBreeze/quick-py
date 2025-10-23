local state = require('quick-py.state')
local env = require('quick-py.env')
local M = {}

function M.SetLsp()
  local root = env.get_venv()
  if not root then return end
  if not state.lsp_started then
    local ok, lspconfig = pcall(require, 'lspconfig')
    if ok then
      lspconfig.pyright.setup({
        cmd = (function()
          local v = vim.env.VIRTUAL_ENV
          local is_win = vim.fn.has('win32') == 1
          if is_win then v = v:gsub('/', '\\'):gsub('\\+$', '') end
          local server = is_win and (v .. '\\Scripts\\pyright-langserver.exe') or (v .. '/bin/pyright-langserver')
          if vim.fn.executable(server) == 1 then
            return { server, '--stdio' }
          else
            return { 'pyright-langserver', '--stdio' }
          end
        end)(),
        root_dir = function(fname)
          local util = require('lspconfig.util')
          local r, _ = require('quick-py.util').find_local_venv(fname)
          if r then return r end
          return util.root_pattern('.git', 'pyproject.toml', 'setup.py')(fname)
        end,
        on_new_config = function(new_config, new_root_dir)
          local v = vim.env.VIRTUAL_ENV
          if v then
            local is_win = vim.fn.has('win32')
            if is_win == 1 then v = v:gsub('/', '\\'):gsub('\\+$', '') end
            local python_venv_path = is_win == 1 and (v .. '\\Scripts\\python.exe') or (v .. '/bin/python')
            if new_config.cmd and new_config.cmd[1] then
              new_config.cmd = { new_config.cmd[1], '--stdio' }
            end
            new_config.settings = new_config.settings or {}
            new_config.settings.python = { analysis = { pythonPath = python_venv_path } }
            new_config.settings.pyright = state.config.lsp_config
          end
        end,
      })
      state.lsp_started = true
    end
  end
end

return M

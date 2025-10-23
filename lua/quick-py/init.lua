-- helper 函数在 config 定义后重载
local M = {}
local cfgmod = require('quick-py.config')
local state = require('quick-py.state')
local env = require('quick-py.env')
local lsp = require('quick-py.lsp')
local term = require('quick-py.terminal')
local cmds = require('quick-py.commands')

function M.setup(user_config)
  state.config = cfgmod.setup(user_config)
  -- 应用键位映射
  for _, keymap in pairs(state.config.keymaps) do
    if type(keymap[2]) == 'string' or type(keymap[2]) == 'function' then
      vim.keymap.set('n', keymap[1], keymap[2], keymap[3] or {})
    end
  end
  -- 自动命令与用户命令
  term.setup_autocmds()
  cmds.setup()
  -- Python 文件自动配置 LSP
  local aug = vim.api.nvim_create_augroup('QuickPyLsp', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
    pattern = '*.py',
    group = aug,
    callback = function()
      lsp.SetLsp()
    end,
  })
  vim.api.nvim_create_user_command('SetLsp', function()
    lsp.SetLsp()
  end, { desc = 'Set LSP for Python' })
end

-- 兼容旧接口（如有用户直接 require('quick-py').get_venv）
M.get_venv = env.get_venv
M.SetLsp = lsp.SetLsp

return M

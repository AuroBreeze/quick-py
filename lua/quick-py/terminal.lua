local state = require('quick-py.state')
local env = require('quick-py.env')
local M = {}

function M.setup_autocmds()
  local aug = vim.api.nvim_create_augroup('ActivateVenv', { clear = true })
  vim.api.nvim_create_autocmd('DirChanged', {
    pattern = '*',
    group = aug,
    callback = function()
      state.cached_root = nil
      state.cached_venv_dir = nil
      state.config.python_path = nil
    end,
  })

  vim.api.nvim_create_autocmd('TermOpen', {
    pattern = '*',
    group = aug,
    callback = function()
      if not state.config.auto_activate_terminal then return end
      local v = env.get_venv()
      local chan = vim.b.terminal_job_id
      if v and chan then
        vim.defer_fn(function()
          local is_win = vim.fn.has('win32') == 1
          if (state.env_type == 'conda') then
            local activate_cmd = is_win and ('conda activate "' .. v .. '"\r') or ('conda activate "' .. v .. '"\n')
            vim.fn.chansend(chan, activate_cmd)
          else
            if is_win then
              vim.fn.chansend(chan, '"' .. v .. '\\Scripts\\activate.bat"\r')
            else
              vim.fn.chansend(chan, 'source ' .. v .. '/bin/activate\n')
            end
          end
        end, 50)
      end
    end,
  })
end

return M

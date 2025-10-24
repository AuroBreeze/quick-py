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
      if vim.g.quick_py_disable_auto_activate == 1 then return end
      if not state.config or not state.config.auto_activate_terminal then return end
      if vim.b.quick_py_activated then return end
      -- 全局防抖：避免短时间内重复触发多个终端激活
      local now = (vim.loop and vim.loop.now and vim.loop.now()) or 0
      local last = vim.g.quick_py_last_activate_ms or 0
      if now > 0 and (now - last) < 200 then return end
      local v = env.get_venv()
      local chan = vim.b.terminal_job_id
      if v and chan then
        vim.defer_fn(function()
          local is_win = vim.fn.has('win32') == 1
          -- 统一使用环境内的激活脚本，避免依赖 shell 初始化（兼容 Windows/Conda）
          if is_win then
            local sh = (vim.o.shell or ''):lower()
            local is_pwsh = sh:find('powershell') or sh:find('pwsh')
            if is_pwsh then
              -- PowerShell/Pwsh 使用 Activate.ps1
              vim.fn.chansend(chan, '& "' .. v .. '\\Scripts\\Activate.ps1"\r')
            else
              -- cmd 等使用 activate.bat
              vim.fn.chansend(chan, '"' .. v .. '\\Scripts\\activate.bat"\r')
            end
          else
            vim.fn.chansend(chan, 'source "' .. v .. '/bin/activate"\n')
          end
          vim.b.quick_py_activated = true
          if now > 0 then vim.g.quick_py_last_activate_ms = now end
        end, 50)
      end
    end,
  })
end

return M

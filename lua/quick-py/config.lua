local M = {}

M.defaults = {
  venv_names = { ".venv", "venv" },
  python_path = nil,
  runserver_cmd = nil,
  max_up_depth = 2,
  max_down_depth = 2,
  auto_activate_terminal = true,
  betterterm = {
    index = 0,
    send_delay = 200,
    focus_on_run = true,
    open_if_closed = true,
  },
  env_detection = { 'local', 'poetry', 'pipenv', 'conda' },
  lsp_config = { typeCheckingMode = "basic" },
  keymaps = {
    run_python = { "<leader>rp", ":RunPython<CR>", { desc = "Run Python file" } },
    set_lsp = { "<leader>rl", ":SetLsp<CR>", { desc = "Set LSP for Python" } },
  },
}

function M.setup(user_config)
  local cfg = vim.deepcopy(M.defaults)
  user_config = user_config and vim.deepcopy(user_config) or {}
  if user_config.venv_names then
    cfg.venv_names = vim.list_extend(vim.deepcopy(cfg.venv_names), user_config.venv_names)
    user_config.venv_names = nil
  end
  if user_config.keymaps then
    cfg.keymaps = vim.tbl_deep_extend("force", cfg.keymaps, user_config.keymaps)
    user_config.keymaps = nil
  end
  cfg = vim.tbl_deep_extend("force", cfg, user_config)
  return cfg
end

return M

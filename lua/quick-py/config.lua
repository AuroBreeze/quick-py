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
  requirements = {
    depth_down = 2,
    depth_up = 0,
    excludes = { '.git', 'node_modules', '.venv', 'venv', '__pycache__', '.mypy_cache', '.pytest_cache', '.cache', 'dist', 'build', '.idea', '.vscode', '.tox' },
    include_all_txt = true,
    strategy = 'pip', -- 'pip'（统一使用 python -m pip）或 'native'（按 env_type 使用原生命令）
  },
  env_detection = { 'local', 'poetry', 'pipenv', 'uv', 'pdm', 'conda' },
  lsp_config = { typeCheckingMode = "basic" },
  keymaps = {
    run_python = { "<leader>rp", ":RunPython<CR>", { desc = "Run Python file" } },
    set_lsp = { "<leader>rl", ":SetLsp<CR>", { desc = "Set LSP for Python" } },
    install_requirements = { "<leader>ri", ":QuickPyInstallReqs<CR>", { desc = "Install from requirements (Telescope)" } },
    toggle_auto_activate = { "<leader>ta", ":QuickPyAutoActivate<CR>", { desc = "Toggle python venv auto activate terminal" } },
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

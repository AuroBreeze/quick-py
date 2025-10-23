local M = {
  cached_root = nil,
  cached_venv_dir = nil,
  env_type = nil, -- 'local'|'poetry'|'pipenv'|'conda'
  lsp_started = false,
  config = nil,
}
return M

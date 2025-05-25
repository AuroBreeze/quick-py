local M = {}
local config = {
    venv_names = { ".venv", "venv" },
    python_path = nil,
}

M.cached_root = nil
M.cached_venv_dir = nil

function M.setup(user_config)
    if user_config and user_config.venv_names then
        config.venv_names = vim.list_extend(config.venv_names, user_config.venv_names)
        user_config.venv_names = nil
    end
    config = vim.tbl_deep_extend("force", config, user_config or {})
end

local function find_local_venv(start_dir)
    local dir = start_dir or vim.fn.expand('%:p:h')
    if dir == '' then dir = vim.fn.getcwd() end
    while dir and dir ~= '/' and dir ~= '' do
        for _, name in ipairs(config.venv_names) do
            local cand = dir .. '/' .. name
            if vim.fn.isdirectory(cand) == 1 then
                return dir, cand
            end
        end
        dir = vim.fn.fnamemodify(dir, ':h')
    end
    return nil, nil
end

function M.activate_venv()
    if M.cached_venv_dir and vim.fn.executable(config.python_path) == 1 then
        return M.cached_venv_dir
    end

    local buf_dir = vim.fn.expand('%:p:h')
    local root_dir, venv = find_local_venv(buf_dir)
    if not root_dir then
        vim.notify("[venvfinder] 未找到 .venv 或 venv", vim.log.levels.WARN)
        return nil
    end

    venv = vim.fn.resolve(venv)
    venv = vim.fn.simplify(venv)
    local is_win = vim.fn.has('win32') == 1
    if is_win then
        venv = venv:gsub('/', '\\'):gsub('\\+$', '')
    else
        venv = venv:gsub('\\', '/'):gsub('/+$', '')
    end

    if M.cached_venv_dir and M.cached_venv_dir ~= venv then
        vim.lsp.stop_client(vim.lsp.get_active_clients({ name = 'pyright' }))
        M.lsp_started = false
    end

    local pybin = is_win and (venv .. '\\Scripts\\python.exe') or (venv .. '/bin/python')
    if vim.fn.executable(pybin) == 0 then
        vim.notify("[venvfinder] Python 不可执行: " .. pybin, vim.log.levels.ERROR)
        return nil
    end

    vim.env.VIRTUAL_ENV = venv
    if is_win then
        vim.env.PATH = venv .. "\\Scripts;" .. vim.env.PATH
    else
        vim.env.PATH = venv .. "/bin:" .. vim.env.PATH
    end
    config.python_path = pybin
    vim.g.python3_host_prog = pybin
    M.cached_root = root_dir
    M.cached_venv_dir = venv
    vim.notify("[venvfinder] 已激活虚拟环境: " .. venv, vim.log.levels.INFO)
    return venv
end

local aug = vim.api.nvim_create_augroup('ActivateVenv', { clear = true })

vim.api.nvim_create_autocmd('DirChanged', {
    pattern = '*',
    group = aug,
    callback = function()
        M.cached_root = nil
        M.cached_venv_dir = nil
        config.python_path = nil
    end,
})

vim.api.nvim_create_autocmd('TermOpen', {
    pattern = '*',
    group = aug,
    callback = function()
        local venv = M.activate_venv()
        local chan = vim.b.terminal_job_id
        if venv and chan then
            vim.defer_fn(function()
                if vim.fn.has('win32') == 1 then
                    vim.fn.chansend(chan, '"' .. venv .. '\\Scripts\\activate.bat"\r')
                else
                    vim.fn.chansend(chan, 'source ' .. venv .. '/bin/activate\n')
                end
            end, 100)
        end
    end,
})

M.lsp_started = false

vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
    pattern = "*.py",
    group = aug,
    callback = function()
        local venv = M.activate_venv()
        if not venv then return end

        if not M.lsp_started then
            local ok, lspconfig = pcall(require, 'lspconfig')
            if ok then
                lspconfig.pyright.setup({
                    cmd = (function()
                        local root, _ = M.activate_venv()
                        local _, venv = find_local_venv(root or vim.fn.getcwd())
                        local is_win = vim.fn.has('win32') == 1
                        if is_win then venv = venv:gsub('/', '\\'):gsub('\\+$', '') end
                        local server = is_win and (venv .. '\\Scripts\\pyright-langserver.exe') or
                            (venv .. '/bin/pyright-langserver')
                        if vim.fn.executable(server) == 1 then
                            return { server, '--stdio' }
                        else
                            return { 'pyright-langserver', '--stdio' }
                        end
                    end)(),
                    root_dir = function(fname)
                        local root, _ = find_local_venv(fname)
                        if root then return root end
                        return lspconfig.util.root_pattern('.git', 'pyproject.toml', 'setup.py')(fname)
                    end,
                    on_new_config = function(new_config, new_root_dir)
                        local _, venv = find_local_venv(new_root_dir)
                        if venv then
                            local is_win = vim.fn.has('win32')
                            if is_win == 1 then venv = venv:gsub('/', '\\'):gsub('\\+$', '') end
                            local python_venv_path = is_win and (venv .. '\\Scripts\\python.exe') or (venv .. '/bin/python')
                            new_config.cmd = { new_config.cmd[1], '--stdio' }
                            new_config.settings = new_config.settings or {}
                            new_config.settings.python = { analysis = { pythonPath = python_venv_path } }
                        end
                    end,
                })
                M.lsp_started = true
            end
        end
    end
})

vim.api.nvim_create_user_command('RunPython', function()
    if not config.python_path then
        vim.notify("[venvfinder] 未激活虚拟环境", vim.log.levels.ERROR)
        return
    end
    local cmd = config.python_path .. ' ' .. vim.fn.shellescape(vim.fn.expand('%:p'))
    local ok2, betterterm = pcall(require, 'betterterm')
    if ok2 then betterterm.exec(cmd) else vim.cmd('!' .. cmd) end
end, { desc = 'Run current Python file in virtualenv' })

M.setup()
return M

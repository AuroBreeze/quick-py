local M = {}
local config = {
    venv_names = { ".venv", "venv" },
    python_path = nil,
    auto_activate = true,
}

-- 缓存项目根和 venv 目录
M.cached_root = nil
M.cached_venv_dir = nil

-- 合并用户配置
function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})
end

-- 向上查找 .venv 或 venv，默认从缓冲区所在目录开始
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

-- 激活虚拟环境并缓存
function M.activate_venv()
    local buf_dir = vim.fn.expand('%:p:h')
    local root_dir, venv = find_local_venv(buf_dir)
    if not root_dir then
        vim.notify("[venvfinder] 未找到 .venv 或 venv", vim.log.levels.WARN)
        return nil
    end
    if M.cached_root == root_dir and config.python_path then
        return M.cached_venv_dir
    end

    local is_win = vim.fn.has('win32') == 1
    -- 统一路径格式：Windows 将所有 '/' 转为 '\', 并去除多余斜杠
    if is_win then
        -- 将所有正斜杠替换为反斜杠
        venv = venv:gsub('/', '\\')
        -- 去除路径末尾多余的反斜杠
        venv = venv:gsub('\\+$', '')
    else
        -- 保持 Unix 风格
        venv = venv:gsub('\\', '/')
                   :gsub('/+$', '')
    end

    local pybin = is_win
        and (venv .. '\\Scripts\\python.exe')
        or (venv .. '/bin/python')
    if vim.fn.executable(pybin) == 0 then
        vim.notify("[venvfinder] Python 不可执行: " .. pybin, vim.log.levels.ERROR)
        return nil
    end
    -- 设置环境变量
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

-- 创建自动命令组
local aug = vim.api.nvim_create_augroup('ActivateVenv', { clear = true })

-- Python 文件打开/切换时激活
vim.api.nvim_create_autocmd({'BufReadPost', 'BufNewFile'}, {
    pattern = '*.py', group = aug,
    callback = M.activate_venv,
})

-- 终端打开时激活并 source/activate
vim.api.nvim_create_autocmd('TermOpen', {
    pattern = '*', group = aug,
    callback = function()
        local venv = M.activate_venv()
        local chan = vim.b.terminal_job_id
        if venv and chan then
            if vim.fn.has('win32') == 1 then
                -- Windows 下激活脚本
                vim.fn.chansend(chan, '"' .. venv .. '\\Scripts\\activate.bat"\r')
            else
                -- Unix 下 source 激活
                vim.fn.chansend(chan, 'source ' .. venv .. '/bin/activate\n')
            end
        end
    end,
})

-- 配置 Pyright LSP
local ok, lspconfig = pcall(require, 'lspconfig')
if ok then
    local function get_cmd_and_python(root_dir)
        local _, venv = find_local_venv(root_dir)
        if venv then
            local is_win = vim.fn.has('win32') == 1
            -- Windows 将斜杠替换
            if is_win then
                venv = venv:gsub('/', '\\'):gsub('\\+$', '')
            end
            -- 设置 pyright-langserver 可执行路径
            local server = is_win
                and (venv .. '\\Scripts\\pyright-langserver.exe')
                or (venv .. '/bin/pyright-langserver')
            local python = is_win
                and (venv .. '\\Scripts\\python.exe')
                or (venv .. '/bin/python')
            if vim.fn.executable(server) == 1 then
                return { server, '--stdio' }, python
            end
        end
        -- 回退到全局安装
        return { 'pyright-langserver', '--stdio' }, vim.fn.exepath('python')
    end

    lspconfig.pyright.setup({
        cmd = get_cmd_and_python(vim.fn.getcwd()),
        root_dir = function(fname)
            return M.cached_root or lspconfig.util.root_pattern('.git', 'pyproject.toml', 'setup.py')(fname)
        end,
        on_new_config = function(new_config, new_root_dir)
            local cmd, python = get_cmd_and_python(new_root_dir)
            new_config.cmd = cmd
            new_config.settings = new_config.settings or {}
            new_config.settings.python = new_config.settings.python or { analysis = {} }
            new_config.settings.python.analysis.pythonPath = python
        end,
    })
end

-- 运行当前 Python 文件命令
vim.api.nvim_create_user_command('RunPython', function()
    if not config.python_path then
        vim.notify("[venvfinder] 未激活虚拟环境", vim.log.levels.ERROR)
        return
    end
    local cmd = config.python_path .. ' ' .. vim.fn.shellescape(vim.fn.expand('%:p'))
    local ok2, betterterm = pcall(require, 'betterterm')
    if ok2 then betterterm.exec(cmd) else vim.cmd('!' .. cmd) end
end, { desc = 'Run current Python file in virtualenv' })

-- 默认加载配置
M.setup()
return M
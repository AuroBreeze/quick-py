-- ~/.config/nvim/lua/venvfinder/init.lua
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

-- 向上查找 .venv 或 venv，起始点可指定（默认当前 buffer 文件目录）
local function find_local_venv(start_dir)
    local dir = start_dir or vim.fn.expand('%:p:h')
    if dir == '' then dir = vim.fn.getcwd() end
    while dir and dir ~= '/' do
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
    -- 优先从 buffer 路径查找
    local buf_dir = vim.fn.expand('%:p:h')
    local root_dir, venv = find_local_venv(buf_dir)
    if not root_dir then
        vim.notify("[venvfinder] 未找到 .venv 或 venv", vim.log.levels.WARN)
        return nil
    end
    -- 如果已缓存同一项目无需重复
    if M.cached_root == root_dir and config.python_path then
        return M.cached_venv_dir
    end
    -- 标准化 venv 目录
    venv = venv:gsub('\\', '/'):gsub('/+$', '')
    local pybin = vim.fn.has('win32')==1 and (venv..'/Scripts/python.exe') or (venv..'/bin/python')
    if vim.fn.executable(pybin)==0 then
        vim.notify("[venvfinder] Python 不可执行: "..pybin, vim.log.levels.ERROR)
        return nil
    end
    -- 设置环境变量与全局 Python
    vim.env.VIRTUAL_ENV = venv
    vim.env.PATH = venv..(vim.fn.has('win32')==1 and '/Scripts;' or '/bin:')..vim.env.PATH
    config.python_path = pybin
    vim.g.python3_host_prog = pybin
    -- 缓存项目根与 venv
    M.cached_root = root_dir
    M.cached_venv_dir = venv
    vim.notify("[venvfinder] 已激活虚拟环境: "..venv, vim.log.levels.INFO)
    return venv
end

-- 创建自动命令组
local aug = vim.api.nvim_create_augroup('ActivateVenv', { clear = true })

-- Python 文件打开/切换时自动激活
vim.api.nvim_create_autocmd({'BufReadPost','BufNewFile'}, {
    pattern = '*.py', group = aug,
    callback = M.activate_venv,
})

-- 终端打开时激活并 source venv
vim.api.nvim_create_autocmd('TermOpen', {
    pattern = '*', group = aug,
    callback = function()
        local venv = M.activate_venv()
        local chan = vim.b.terminal_job_id
        if venv and chan then
            if vim.fn.has('win32')==1 then
                vim.fn.chansend(chan, venv..'/Scripts/activate.bat\r')
            else
                vim.fn.chansend(chan, 'source '..venv..'/bin/activate\n')
            end
        end
    end,
})

-- 配置 Pyright LSP
local ok, lspconfig = pcall(require, 'lspconfig')
if ok then
    lspconfig.pyright.setup({
        cmd = { 'pyright-langserver', '--stdio' },
        root_dir = function(fname)
            return M.cached_root or lspconfig.util.root_pattern('.git', 'pyproject.toml', 'setup.py')(fname)
        end,
        on_new_config = function(new_config, new_root_dir)
            -- 针对每个 workspace 配置 venv
            local _, venv = find_local_venv(new_root_dir)
            if venv then
                local pybin = (vim.fn.has('win32')==1) and (venv..'/Scripts/python.exe') or (venv..'/bin/python')
                if vim.fn.executable(pybin)==1 then
                    new_config.cmd = { pybin, '-m', 'pyright_langserver', '--stdio' }
                    new_config.settings = new_config.settings or {}
                    new_config.settings.python = new_config.settings.python or { analysis = {} }
                    new_config.settings.python.analysis.pythonPath = pybin
                end
            end
        end,
    })
end

-- 运行 Python 命令
vim.api.nvim_create_user_command('RunPython', function()
    if not config.python_path then
        vim.notify("[venvfinder] 未激活虚拟环境", vim.log.levels.ERROR)
        return
    end
    local cmd = config.python_path..' '..vim.fn.shellescape(vim.fn.expand('%:p'))
    local ok2 = pcall(require, 'betterterm')
    if ok2 then require('betterterm').exec(cmd) else vim.cmd('!'..cmd) end
end, { desc = 'Run current Python file in virtualenv' })

-- 默认加载配置
M.setup()
return M

-- ~/.config/nvim/lua/quick-py/init.lua
local M = {}
local config = {
    venv_names = { ".venv", "venv" },
    python_path = nil,
    auto_activate = true,
}

-- 缓存上次激活的项目根和 venv 目录
M.cached_root = nil
M.cached_venv_dir = nil

-- 合并用户配置
function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})
end

-- 向上查找 .venv 或 venv 同级目录
local function find_local_venv()
    local dir = vim.fn.getcwd()
    while dir and dir ~= '/' do
        for _, name in ipairs(config.venv_names) do
            local candidate = dir .. '/' .. name
            if vim.fn.isdirectory(candidate) == 1 then
                return dir, candidate
            end
        end
        dir = vim.fn.fnamemodify(dir, ':h')
    end
    return nil, nil
end

-- 激活虚拟环境，带缓存判断
function M.activate_venv()
    local cwd = vim.fn.getcwd()
    if M.cached_root == cwd and config.python_path then
        return M.cached_venv_dir
    end
    local root, venv_dir = find_local_venv()
    if not root then
        vim.notify("[venvfinder] 未在任何父目录中找到 .venv 或 venv", vim.log.levels.WARN)
        return nil
    end
    venv_dir = venv_dir:gsub('\\', '/'):gsub('/+$', '')
    local python_bin = vim.fn.has('win32') == 1
        and (venv_dir .. '/Scripts/python.exe')
        or (venv_dir .. '/bin/python')
    if vim.fn.executable(python_bin) == 0 then
        vim.notify("[venvfinder] 虚拟环境中未找到 Python: " .. python_bin, vim.log.levels.ERROR)
        return nil
    end
    -- 设置环境变量
    vim.env.VIRTUAL_ENV = venv_dir
    vim.env.PATH = venv_dir .. (vim.fn.has('win32') == 1 and '/Scripts;' or '/bin:') .. vim.env.PATH
    config.python_path = python_bin
    vim.g.python3_host_prog = python_bin
    -- 缓存
    M.cached_root = cwd
    M.cached_venv_dir = venv_dir
    vim.notify("[venvfinder] 已激活虚拟环境: " .. venv_dir, vim.log.levels.INFO)
    return venv_dir
end

-- 自动命令组
local aug = vim.api.nvim_create_augroup('ActivateVenv', { clear = true })

-- Python 文件打开时激活
vim.api.nvim_create_autocmd({'BufEnter','BufNewFile'}, {
    pattern = '*.py', group = aug,
    callback = function() M.activate_venv() end,
})

-- 终端打开时激活并在终端内 source/activate
vim.api.nvim_create_autocmd('TermOpen', {
    pattern = '*', group = aug,
    callback = function()
        local venv_dir = M.activate_venv()
        local chan = vim.b.terminal_job_id
        if venv_dir and chan then
            if vim.fn.has('win32') == 1 then
                vim.fn.chansend(chan, venv_dir .. '/Scripts/activate.bat\r')
            else
                vim.fn.chansend(chan, 'source ' .. venv_dir .. '/bin/activate\n')
            end
        end
    end,
})

-- LSP: 配置 pyright 使用虚拟环境
local function setup_pyright()
    local ok, lspconfig = pcall(require, 'lspconfig')
    if not ok then return end
    lspconfig.pyright.setup({
        before_init = function(_, config_)
            M.activate_venv()
            if config.python_path then
                config_.settings = config_.settings or {}
                config_.settings.python = config_.settings.python or {}
                config_.settings.python.pythonPath = config.python_path
                -- 兼容 analysis.pythonPath
                config_.settings.python.analysis = config_.settings.python.analysis or {}
                config_.settings.python.analysis.pythonPath = config.python_path
            end
        end,
        root_dir = function(fname)
            return M.cached_root or lspconfig.util.root_pattern('.git')(fname)
        end,
    })
end

-- 初始化
setup_pyright()

-- 运行当前 Python 文件命令
vim.api.nvim_create_user_command('RunPython', function()
    if not config.python_path then
        vim.notify("[venvfinder] 未激活虚拟环境", vim.log.levels.ERROR)
        return
    end
    local cmd = config.python_path .. ' ' .. vim.fn.shellescape(vim.fn.expand('%:p'))
    local ok = pcall(require, 'betterterm')
    if ok then require('betterterm').exec(cmd)
    else vim.cmd('!' .. cmd) end
end, { desc = 'Run current Python file in virtualenv' })

-- 默认加载配置
M.setup()
return M

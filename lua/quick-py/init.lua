local M = {}
local config = {
    venv_names = { ".venv", "venv" },
    python_path = nil,
    runserver_cmd = nil, -- 运行自定义python命令 ，例如django： python manage.py runserver
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
    local dir = start_dir or vim.fn.expand('%:p:h') -- 获取当前文件所在目录
    if dir == '' then dir = vim.fn.getcwd() end -- 如果没有就使用当前工作目录
    while dir and dir ~= '/' and dir ~= '' do -- 递归查找
        for _, name in ipairs(config.venv_names) do -- 遍历设置的虚拟环境名称
            local cand = dir .. '/' .. name -- 将虚拟环境名称与目录拼接
            if vim.fn.isdirectory(cand) == 1 then -- 验证拼接的目录是否存在
                return dir, cand
            end
        end
        dir = vim.fn.fnamemodify(dir, ':h') -- 获取上一级目录
    end
    return nil, nil
end

function M.get_venv()
    if M.cached_venv_dir and vim.fn.executable(config.python_path) == 1 then -- 缓存的虚拟环境可用
        return M.cached_venv_dir
    end

    local buf_dir = vim.fn.expand('%:p:h') -- 获取当前文件所在目录
    local root_dir, venv = find_local_venv(buf_dir) -- 获取虚拟环境目录
    if not root_dir then
        vim.notify("[Quick-py] 未找到 .venv 或 venv", vim.log.levels.WARN)
        return nil
    end

    venv = vim.fn.resolve(venv) -- 将路径展开
    venv = vim.fn.simplify(venv) -- 处理路径中无用的字符
    local is_win = vim.fn.has('win32') == 1 -- 判断系统类型
    if is_win then -- windows系统需要将路径中的分隔符替换为反斜杠
        venv = venv:gsub('/', '\\'):gsub('\\+$', '')
    else
        venv = venv:gsub('\\', '/'):gsub('/+$', '')
    end

    if M.cached_venv_dir and M.cached_venv_dir ~= venv then  -- 缓存的虚拟环境不匹配
        vim.lsp.stop_client(vim.lsp.get_active_clients({ name = 'pyright' }))
        M.lsp_started = false
    end

    -- 三元条件判断
    -- 若is_win为true（Windows系统），则路径为venv目录下的\\Scripts\\python.exe 否则（Unix/Linux系统），路径为venv目录下的/bin/python
    local pybin = is_win and (venv .. '\\Scripts\\python.exe') or (venv .. '/bin/python')
    if vim.fn.executable(pybin) == 0 then -- 验证python可执行
        vim.notify("[Quick-py] Python 不可执行: " .. pybin, vim.log.levels.ERROR)
        return nil
    end

    vim.env.VIRTUAL_ENV = venv -- 设置环境变量
    if is_win then
        vim.env.PATH = venv .. "\\Scripts;" .. vim.env.PATH
    else
        vim.env.PATH = venv .. "/bin:" .. vim.env.PATH
    end
    config.python_path = pybin -- 缓存python路径
    vim.g.python3_host_prog = pybin -- 缓存python路径到全局变量
    M.cached_root = root_dir -- 缓存根目录
    M.cached_venv_dir = venv -- 缓存虚拟环境目录
    vim.notify("[Quick-py] 已找到虚拟环境: " .. venv, vim.log.levels.INFO)
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
        local venv = M.get_venv()
        local chan = vim.b.terminal_job_id
        if venv and chan then
            vim.defer_fn(function() -- 延迟执行
                if vim.fn.has('win32') == 1 then
                    vim.fn.chansend(chan, '"' .. venv .. '\\Scripts\\activate.bat"\r') -- 发送激活命令
                else
                    vim.fn.chansend(chan, 'source ' .. venv .. '/bin/activate\n')
                end
            end, 50)
        end
    end,
})

M.lsp_started = false

function M.activate_lsp()
     local root = M.get_venv() -- 设置环境变量，并返回虚拟环境目录
        if not root then return end

        if not M.lsp_started then
            local ok, lspconfig = pcall(require, 'lspconfig') -- 加载lspconfig插件
            if ok then
                lspconfig.pyright.setup({
                    cmd = (function()
                        -- local _, venv = find_local_venv(root or vim.fn.getcwd())
                        local venv = vim.env.VIRTUAL_ENV
                        local is_win = vim.fn.has('win32') == 1
                        if is_win then venv = venv:gsub('/', '\\'):gsub('\\+$', '') end
                        local server = is_win and (venv .. '\\Scripts\\pyright-langserver.exe') or
                            (venv .. '/bin/pyright-langserver')
                        if vim.fn.executable(server) == 1 then
                            return { server, '--stdio' } -- 找到pyright-langserver时，使用配置
                        else
                            return { 'pyright-langserver', '--stdio' } -- 未找到pyright-langserver时，使用默认配置
                        end
                    end)(),
                    root_dir = function(fname)
                        local root, _ = find_local_venv(fname)
                        if root then return root end
                        return lspconfig.util.root_pattern('.git', 'pyproject.toml', 'setup.py')(fname)
                    end,
                    on_new_config = function(new_config, new_root_dir)
                        -- local _, venv = find_local_venv(new_root_dir)
                        local venv = vim.env.VIRTUAL_ENV
                        if venv then
                            local is_win = vim.fn.has('win32')
                            if is_win == 1 then venv = venv:gsub('/', '\\'):gsub('\\+$', '') end
                            local python_venv_path = is_win and (venv .. '\\Scripts\\python.exe') or
                            (venv .. '/bin/python')
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
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
    pattern = "*.py", -- 匹配Python文件
    group = aug,
    callback = M.activate_lsp,
        
})

vim.api.nvim_create_user_command('RunPython', function()
    if not vim.env.VIRTUAL_ENV then
        vim.notify("[Quick-py] 未找到虚拟环境", vim.log.levels.ERROR)
        return
    end
    local cmd -- 处理自定义命令
    if config.runserver_cmd then
        cmd = config.runserver_cmd
    else 
        cmd = "python" .. ' ' .. vim.fn.shellescape(vim.fn.expand('%:p'))
    end
    local ok, betterTerm = pcall(require, 'betterTerm')
    if ok then
        -- 手动发送激活命令到终端
        -- local venv = M.activate_venv()
        -- if not venv then return end

        local chan = betterTerm.open(0)
        if not chan then
            betterTerm.open(0) -- 如果终端未打开，先打开
        end
        vim.defer_fn(function()
            betterTerm.send(cmd .. '\r',0) -- 注意加回车符
        end, 200)

        betterTerm.open(0)
    else
        -- 普通终端模式：直接执行（需用户手动激活环境）
        vim.cmd('!' .. cmd)
    end
end, { desc = 'Run current Python file in virtualenv' })

vim.keymap.set("n", "<leader>rp", ":RunPython<CR>", { desc = "Run Python file" })

M.setup()
return M

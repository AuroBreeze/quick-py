## Quick-py v1.0.0 发布说明

### 核心功能
1. **智能虚拟环境激活**
   - 自动扫描项目目录下的 `.venv` 或 `venv` 虚拟环境
   - 动态设置 `VIRTUAL_ENV` 和 `PATH` 环境变量
   - 支持跨平台（Windows/Linux/macOS）
   - 终端自动激活虚拟环境（快捷键：`<leader>rp` 或 `ctrl+/`/`ctrl+;`）

2. **LSP 集成优化**
   - 自动配置 Pyright 语言服务器路径
   - 动态绑定虚拟环境中的 Python 解释器
   - 支持项目根目录智能识别（通过 `.git`/`pyproject.toml` 等）

3. **终端增强功能**
   - 新建终端时自动注入虚拟环境激活命令
   - 支持 `betterTerm` 插件的异步执行（若已安装）
   - 终端快捷键：`<C-;>` 和 `<C-/>`

4. **快捷执行**
   - 提供 `:RunPython` 命令执行当前文件
   - 支持自定义运行命令（如 Django 的 `manage.py runserver`）
   - 默认快捷键 `<leader>rp`

### 配置示例
```lua
-- init.lua 配置片段
require('quick-py').setup({
    venv_names = { ".venv", "venv" }, -- 自定义虚拟环境名称
    python_path = nil,               -- 手动指定 Python 路径（可选）
    runserver_cmd = "python manage.py runserver" -- 自定义运行命令
})
```

### 安装要求
- Neovim 0.9+
- Python 3.8+ 环境
- 可选依赖：`betterTerm`（增强终端功能）

### 已知限制
- Windows 路径需使用正则斜杠 [/]（自动转换处理）
- 首次激活虚拟环境时需手动触发目录切换
- 需在项目文件夹下打开 nvim 以确保功能正常
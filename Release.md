## Quick-py v1.4.0 发布说明

发布时间：2025-10-23

### 变更摘要
- 新增：多环境支持（Poetry/Pipenv/Conda）与多系统适配。
- 提升：betterTerm 调用更健壮，失败时自动回退普通执行。
- 新增：命令 `QuickPyAutoActivate` 用于控制终端自动激活开关。
- 新增：内置 Healthcheck，支持 `:CheckHealth quick-py`。
- 提升：`RunPython` 使用虚拟环境解释器执行并在失败时保持终端窗口不关闭。

### 新增/改进
- 多环境检测优先级（可配置）：`env_detection = { 'local', 'poetry', 'pipenv', 'conda' }`
  - Poetry：识别 `pyproject.toml` 并通过 `poetry env info -p` 获取 venv。
  - Pipenv：识别 `Pipfile` 并通过 `pipenv --venv` 获取 venv。
  - Conda：优先使用 `CONDA_PREFIX`，终端激活用 `conda activate "<env>"`。
- betterTerm 健壮性：
  - 避免依赖返回通道；支持延迟发送、自动创建终端、发送后聚焦等。
  - 新配置 `betterterm = { index, send_delay, focus_on_run, open_if_closed }`。
- 终端自动激活可控：
  - 新命令 `QuickPyAutoActivate [on|off|toggle]`。
  - 配置项 `auto_activate_terminal` 仍可用。
- 健康检查：
  - `:CheckHealth quick-py` 检查 Python、Pyright、betterTerm、project.nvim 及 Shell 提示。

### 其他
- 代码重构为多模块：`config/state/util/env/lsp/terminal/commands`，`init.lua` 仅负责装配与导出接口。

---

## Quick-py v1.3.0 发布说明

发布时间：2025-10-23

### 变更摘要
- 新增：可配置最大向上/向下寻找深度，默认 2。
- 修复：Windows 根目录终端卡死问题。
- 提升：虚拟环境发现更稳健。

### 新增功能
- 最大向上寻找深度 `max_up_depth`（默认 2）
- 最大向下寻找深度 `max_down_depth`（默认 2）

### 问题修复
- 修复 `find_local_venv()` 在 Windows 根目录父目录等于自身时的无限循环，避免在 `TermOpen` 中卡死终端。

### 配置示例
```lua
require('quick-py').setup({
  venv_names = { ".venv", "venv" },
  max_up_depth = 2,
  max_down_depth = 2,
})
```

---

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
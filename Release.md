## Quick-py v1.5.0 发布说明

发布时间：2025-10-24

### 变更摘要
- 新增：启动顺序鲁棒性与重复激活保护。
- 新增：环境检测扩展，支持 `uv` 与 `pdm`。
- 提升：Windows/Conda 兼容性，统一使用环境内激活脚本；新增 PowerShell/Pwsh 专用分支。
- 提升：增加防抖，避免短时间内多终端并发重复注入。
- 提升：PATH 幂等处理与跨平台路径规范化，避免重复前置 `Scripts/bin`。
- 文档：完善 `runserver_cmd` 使用说明，README 同步更新。
 - 新增：Telescope 驱动的 requirements 安装器（`:QuickPyInstallReqs`）。
 - 变更：当 `auto_activate_terminal = false` 时，跳过虚拟环境探测与 PATH 注入。

### 详情
- 启动鲁棒性与重复激活
  - `TermOpen` 回调加入全局禁用开关：`vim.g.quick_py_disable_auto_activate == 1` 时跳过。
  - 判空 `state.config`，避免在 `setup()` 之前读取默认值误触发。
  - 缓冲区标记 `vim.b.quick_py_activated` 防止同一终端多次注入。
- 环境检测扩展（`env.lua`）
  - 新增 `uv`、`pdm` 检测，默认顺序更新为 `{ 'local','poetry','pipenv','uv','pdm','conda' }`。
  - 策略：优先在项目根基于 `pyproject.toml` 查找本地 `.venv`。
- Windows/Conda 兼容（`terminal.lua`）
  - 统一直接执行环境目录内激活脚本：
    - Windows：`"<venv>\\Scripts\\activate.bat"`
    - Unix：`source "<venv>/bin/activate"`
  - 当 shell 为 PowerShell/Pwsh 时，改为：`& "<venv>\\Scripts\\Activate.ps1"`。
- 防抖处理（`terminal.lua`）
  - 使用 `vim.loop.now()` 做 200ms 防抖，避免短时多次触发。
- PATH 幂等与路径规范化（`util.lua`、`env.lua`）
  - 新增 `normalize_path`、`path_join`、`prepend_env_path_once`。
  - 通过 `prepend_env_path_once` 幂等地前置 `Scripts/bin`，避免重复追加。
- 文档
  - README 增加 `:SetRunPythonCmd` 用法与持久化/重置提示。
  - 激活脚本说明同步 PowerShell 分支与跨平台行为描述。
  - 新增 requirements 安装器说明：支持文件预览、多选安装、快捷键 `<leader>ri`、可配置扫描（`depth_up`/`depth_down`/`excludes`/`include_all_txt`）。
  - 标注配置项影响：`auto_activate_terminal = false` 将关闭 venv 探测与 PATH 注入，相关能力不再自动生效。

### 新增：requirements 安装器（Telescope）
- 命令：`:QuickPyInstallReqs`
- 依赖：`nvim-telescope/telescope.nvim`、`nvim-lua/plenary.nvim`
- 能力：
  - 异步扫描 `requirements*.txt`（可选包含所有 `*.txt`）并展示文件预览。
  - 选择包（支持多选）后自动使用当前 venv Python 执行 `python -m pip install`。
  - 默认键位：`<leader>ri`。
- 可配项（`config.requirements`）：
  - `depth_down`、`depth_up`、`excludes`、`include_all_txt`。

---

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
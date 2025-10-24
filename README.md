# Quick-Py

<a href="https://dotfyle.com/plugins/AuroBreeze/quick-py">
	<img src="https://dotfyle.com/plugins/AuroBreeze/quick-py/shield?style=for-the-badge" />
</a>

--- 

## Instructions

`neovim-plugins`一个在`lazyvim`快速使用python的插件

---

## Features
- [x] 终端自动激活虚拟环境 `ctrl+/`或`ctrl+;`
- [x] 使用虚拟环境的`pyright`进行代码检查
- [x] 运行自定义命令（通过运行 `:SetRunPythonCmd` 设置运行命令）
- [x] 一键运行代码`<leader>rp`
- [x] 可配置最大向上/向下寻找深度（`max_up_depth`/`max_down_depth`，默认 2）
- [x] 终端自动激活可开关（`auto_activate_terminal`，默认开启；支持命令控制）
- [x] 多环境支持（`local`/`poetry`/`pipenv`/`uv`/`pdm`/`conda`）与多系统适配
- [x] 运行失败终端不关闭（`RunPython` 始终在终端中执行并保留窗口）
- [x] 基于 Telescope 的 requirements 安装器（`:QuickPyInstallReqs`）


---

## Install 

### lazy.vim

```lua
return {
    "AuroBreeze/quick-py",
    dependencies={
        "ahmedkhalf/project.nvim",
        "nvim-telescope/telescope.nvim",
        "CRAG666/betterTerm.nvim",
        "nvim-lua/plenary.nvim"
    },
    lazy =true,
    event = "VeryLazy",

    config = {
    -- 本地虚拟环境目录名称（按顺序尝试）
    venv_names = { ".venv", "venv" },

    -- Python 解释器路径（留空则自动从虚拟环境推断）
    python_path = nil,

    -- 自定义运行命令（优先于默认运行当前文件）
    -- 可用命令动态设置：:SetRunPythonCmd <command>
    runserver_cmd = nil, -- 例如："python manage.py runserver" / "uvicorn app.main:app --reload"

    -- 本地 venv 查找范围（向上/向下）
    max_up_depth = 2,   -- 向上回溯父目录层数
    max_down_depth = 2, -- 在每层目录内向下递归的最大深度

    -- 打开终端时是否自动注入激活脚本
    -- 也可命令控制：:QuickPyAutoActivate on|off|toggle
    auto_activate_terminal = true,

    -- betterTerm 相关行为（若已安装 CRAG666/betterTerm.nvim）
    betterterm = {
      index = 0,            -- 目标终端编号
      send_delay = 200,     -- 发送命令前的延迟（毫秒）
      focus_on_run = true,  -- 发送命令后是否聚焦终端
      open_if_closed = true -- 目标终端未开启时自动打开
    },

    -- requirements 扫描安装器（Telescope）的搜索配置
    requirements = {
      depth_down = 2,       -- 向下扫描深度（默认示例 2；推荐 6）
      depth_up = 0,         -- 向上回溯层数（0 = 仅当前工作目录）
      excludes = {          -- 排除目录名（逐段匹配）
        '.git', 'node_modules', '.venv', 'venv', '__pycache__', '.mypy_cache',
        '.pytest_cache', '.cache', 'dist', 'build', '.idea', '.vscode', '.tox',
      },
      include_all_txt = true, -- 是否包含所有 *.txt（否则仅匹配 requirements*.txt）
    },

    -- 环境检测优先级（按顺序尝试）
    env_detection = { 'local', 'poetry', 'pipenv', 'uv', 'pdm', 'conda' },

    -- Pyright 配置（会在 on_new_config 中注入当前 venv 的 python 路径）
    lsp_config = { typeCheckingMode = "basic" },

    -- 键位映射（可用 :SetPyKeymap <name> <key> 动态修改）
    keymaps = {
      run_python = { "<leader>rp", ":RunPython<CR>", { desc = "Run Python file" } }, -- 一键运行
      set_lsp = { "<leader>rl", ":SetLsp<CR>", { desc = "Set LSP for Python" } }, -- 设置本地LSP
      install_requirements = { "<leader>ri", ":QuickPyInstallReqs<CR>", { desc = "Install from requirements (Telescope)" } }, -- 安装requirements
      toggle_auto_activate = { "<leader>ta", ":QuickPyAutoActivate<CR>", { desc = "Toggle python venv auto activate terminal" } }, -- 自动激活虚拟环境
    },
  }
}
```
---

### packer.nvim

```lua
use { "AuroBreeze/quick-py", requires = { "ahmedkhalf/project.nvim", "neovim/nvim-lspconfig","CRAG666/betterTerm.nvim" } }
```
## Configuration

```lua
config = {
    venv_names = { ".venv", "venv" },
    python_path = nil,
    runserver_cmd = nil, -- 运行自定义python命令 ，例如django： python manage.py runserver
    max_up_depth = 2,    -- 最大向上寻找深度（默认 2）
    max_down_depth = 2,  -- 最大向下寻找深度（默认 2）
    lsp_config = {
        typeCheckingMode = "off"
    }, -- 语言服务器配置
    -- 新增键位配置
    keymaps = {
        run_python = { "<leader>rp", ":RunPython<CR>", { desc = "Run Python file" } },
        set_lsp = { "<leader>rl", ":SetLsp<CR>", { desc = "Set LSP for Python" } },
    }
}


```

## Plugins

> 对于依赖的三个插件，只需要配置`"CRAG666/betterTerm.nvim"`就可以了，可以按照作者的配置来。

这是作者的配置

```lua
return {
  'CRAG666/betterTerm.nvim',
  lazy =true,
  event="VeryLazy",
  keys = {
    {
      mode = { 'n', 't' },
      '<C-;>',
      function()
        require('betterTerm').open()
      end,
      desc = 'Open BetterTerm 0',
    },
    {
      mode = { 'n', 't' },
      '<C-/>',
      function()
        require('betterTerm').open(1)
      end,
      desc = 'Open BetterTerm 1',
    },
    {
      '<leader>tt',
      function()
        require('betterTerm').select()
      end,
      desc = 'Select terminal',
    }
  },
  opts = {
    position = 'bot',
    size = 20,
    jump_tab_mapping = "<A-$tab>"
  },
}
```

## Language Servers

+ pyright

## Usage

> [!NOTE]
> 请在项目文件夹下打开`nvim`，防止其他错误出现。

### 控制终端自动激活

你可以通过配置或命令控制是否在打开终端时自动注入虚拟环境激活脚本：

```vim
" 开启/关闭/切换
:QuickPyAutoActivate on
:QuickPyAutoActivate off
:QuickPyAutoActivate toggle

" 无参等同于 toggle
:QuickPyAutoActivate
```

也可以在 setup 中设置默认行为：

```lua
require('quick-py').setup({
  auto_activate_terminal = true, -- 设为 false 则默认不自动注入
})
```

> [!IMPORTANT]
> 当 `auto_activate_terminal = false` 时，插件将跳过虚拟环境探测与 PATH 注入，以降低开销。
> 这意味着依赖 venv 探测的行为（如自动为 Pyright 绑定 venv、`RunPython` 使用 venv 解释器）将不再自动生效。
> 如果你仅想关闭“终端内激活”而仍希望 LSP/运行继续使用 venv，请将其设为 `true`，并仅通过命令在需要时临时关闭：`:QuickPyAutoActivate off`。
> 或者在配置中手动指定 `python_path`，或在需要时运行 `:SetLsp` 以手动配置 LSP。

### 运行行为说明（RunPython）

- **使用解释器**：默认使用虚拟环境中的 Python 可执行文件（`python_path`），无需依赖终端内激活的 PATH。
- **窗口保持**：始终在终端中执行命令并保留窗口，便于查看错误信息。
- **优先级**：优先使用 `betterTerm`；如不可用或发送失败，自动回退到内置终端分屏。
- **betterTerm 注意**：为避免窗口被二次 `open()` 触发 toggle 收起，发送后不再重复 `open()`；如仍有异常，可将 `betterterm.focus_on_run = false`。

### 设置自定义运行命令（runserver_cmd）

- **临时设置（当前会话有效）**：
  ```vim
  :SetRunPythonCmd python manage.py runserver
  :SetRunPythonCmd uvicorn app.main:app --reload
  :SetRunPythonCmd poetry run uvicorn app.main:app --reload
  ```
- **持久化设置**：在你的配置中传入 `runserver_cmd`：
  ```lua
  require('quick-py').setup({
    runserver_cmd = 'python manage.py runserver',
  })
  ```
- **恢复默认（取消自定义）**：
  ```vim
  :lua require('quick-py.state').config.runserver_cmd = nil
  ```

### requirements 安装器（Telescope）

- **命令**：
  ```vim
  :QuickPyInstallReqs
  ```
- **行为**：
  - 异步扫描当前工作目录（默认深度 6）下的 `requirements*.txt` 与 `*.txt` 文件。
  - 先选择文件，再选择要安装的包。
  - 自动使用当前虚拟环境 Python 执行：`python -m pip install <包...>`。
- **预览**：
  - 选择文件时右侧显示该 txt 文件内容（Telescope 预览器）。
- **整文件安装**：
  - 在包列表中提供特定项“[Install ALL from this file]”，选择后直接执行整文件安装：`python -m pip install -r <所选文件>`。
- **多选安装**：
  - 在包列表中可使用 Telescope 多选（例如 `<Tab>` 标记多个，`<CR>` 确认）。
- **依赖**：
  - 需要安装 `nvim-telescope/telescope.nvim` 与 `nvim-lua/plenary.nvim`。
  - 已在 `Install` 示例的 `dependencies` 中列出。
- **快捷键**：
  - 默认提供 `<leader>ri` 触发 `:QuickPyInstallReqs`（可用 `:SetPyKeymap install_requirements <newkey>` 调整）。

#### 扫描范围配置

```lua
require('quick-py').setup({
  requirements = {
    depth_down = 6,   -- 向下扫描深度
    depth_up = 0,     -- 向上回溯层数（逐级父目录也会各自向下扫描）
    excludes = {      -- 排除目录名（逐段匹配）
      '.git', 'node_modules', '.venv', 'venv', '__pycache__', '.mypy_cache',
      '.pytest_cache', '.cache', 'dist', 'build', '.idea', '.vscode', '.tox',
    },
    include_all_txt = true, -- 是否包含所有 *.txt（否则仅匹配 requirements*.txt）
  },
})
```

### Healthcheck

使用内置健康检查查看环境与依赖状态：

```vim
:CheckHealth quick-py
```

报告会检查：
- Python（优先虚拟环境）
- Pyright（虚拟环境/系统）
- 可选依赖：betterTerm、project.nvim
- 当前 Shell 与激活脚本提示

### 激活脚本说明

- 所有环境（包括 conda）均优先直接执行环境目录内的激活脚本：
  - Windows：执行 `"<venv>\Scripts\activate.bat"`
  - Unix：执行 `source <venv>/bin/activate`
  这样避免依赖外部 shell 初始化（如 `conda init`），提高跨平台一致性。

---

## Module Structure

```
lua/quick-py/
  init.lua        # 入口与编排（setup/键位/LSP 自动命令、导出接口）
  config.lua      # 默认配置与合并逻辑
  state.lua       # 运行时状态（缓存/配置/env 类型/LSP 状态）
  util.lua        # 工具函数（目录查找/系统命令执行）
  env.lua         # 环境检测与注入（local/poetry/pipenv/conda）
  lsp.lua         # Pyright 配置绑定 venv
  terminal.lua    # 自动命令（DirChanged/TermOpen 激活）
  commands.lua    # 用户命令（RunPython/SetRunPythonCmd/SetPyKeymap/QuickPyAutoActivate）
```

---

## Contribution
> 欢迎大家提出建议和意见，帮助完善这个插件。

---

## Importance

> 这个插件是我为快速使用`python`而写的，写的比较匆忙。
> 如果这个插件有问题，希望大家能够指出或修复，感谢。

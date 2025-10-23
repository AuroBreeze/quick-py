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
- [x] 运行自定义命令(通过运行`:SetRunserverCmd`设置运行命令)
- [x] 一键运行代码`<leader>rp`
- [x] 可配置最大向上/向下寻找深度（`max_up_depth`/`max_down_depth`，默认 2）
- [x] 终端自动激活可开关（`auto_activate_terminal`，默认开启；支持命令控制）
- [x] 多环境支持（`local`/`poetry`/`pipenv`/`conda`）与多系统适配
- [x] 运行失败终端不关闭（`RunPython` 始终在终端中执行并保留窗口）


---

## Install 

### lazy.vim

```lua
return {
    "AuroBreeze/quick-py",
    dependencies={
        "ahmedkhalf/project.nvim"
    },
    lazy =true,
    event = "VeryLazy",

    config = {
    venv_names = { ".venv", "venv" },
    python_path = nil,
    runserver_cmd = nil, -- 运行自定义python命令 ，例如django： python manage.py runserver
    max_up_depth = 2,    -- 最大向上寻找深度（默认 2）
    max_down_depth = 2,  -- 最大向下寻找深度（默认 2）
    auto_activate_terminal = true, -- 终端打开时自动激活（可设为 false 关闭）
    env_detection = { 'local', 'poetry', 'pipenv', 'conda' }, -- 环境检测优先级
    betterterm = {
      index = 0,            -- 目标终端编号
      send_delay = 200,     -- 发送前延迟（毫秒）
      focus_on_run = true,  -- 发送后聚焦终端
      open_if_closed = true -- 未打开则自动打开
    },
    lsp_config = {
        typeCheckingMode = "off"
    }, -- 语言服务器配置
    -- 新增键位配置
    keymaps = {
        run_python = { "<leader>rp", ":RunPython<CR>", { desc = "Run Python file" } },
        set_lsp = { "<leader>rl", ":SetLsp<CR>", { desc = "Set LSP for Python" } },
        toggle_auto_activate = { "<leader>tpa", ":QuickPyAutoActivate<CR>", { desc = "Toggle auto activate terminal" } },
    }
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

### 运行行为说明（RunPython）

- **使用解释器**：默认使用虚拟环境中的 Python 可执行文件（`python_path`），无需依赖终端内激活的 PATH。
- **窗口保持**：始终在终端中执行命令并保留窗口，便于查看错误信息。
- **优先级**：优先使用 `betterTerm`；如不可用或发送失败，自动回退到内置终端分屏。
- **betterTerm 注意**：为避免窗口被二次 `open()` 触发 toggle 收起，发送后不再重复 `open()`；如仍有异常，可将 `betterterm.focus_on_run = false`。

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

- local/poetry/pipenv 环境：
  - Windows：执行 `"<venv>\Scripts\activate.bat"`
  - Unix：执行 `source <venv>/bin/activate`
- conda 环境：
  - 发送 `conda activate "<env>"`（建议先执行 `conda init` 以确保 shell 支持）

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

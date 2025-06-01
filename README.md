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
    lsp_config = {
        typeCheckingMode = "off"
    }, -- 语言服务器配置
    -- 新增键位配置
    keymaps = {
        run_python = { "<leader>rp", ":RunPython<CR>", { desc = "Run Python file" } },
        set_lsp = { "<leader>rl", ":SetLsp<CR>", { desc = "Set LSP for Python" } },
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

---

## Contribution
> 欢迎大家提出建议和意见，帮助完善这个插件。

---

## Importance

> 这个插件是我为快速使用`python`而写的，写的比较匆忙。
> 如果这个插件有问题，希望大家能够指出或修复，感谢。

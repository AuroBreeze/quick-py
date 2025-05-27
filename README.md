# Quick-Py

<a href="https://dotfyle.com/plugins/AuroBreeze/quick-py">
	<img src="https://dotfyle.com/plugins/AuroBreeze/quick-py/shield?style=for-the-badge" />
</a>

--- 

## Instructions

`neovim-plugins`一个在`lazyvim`快速使用python的插件

---

## Features
- [x] 终端自动激活虚拟环境
- [x] 使用虚拟环境的`pyright`进行代码检查
- [x] 运行自定义命令
- [x] 一键运行代码


---

## Install 

### lazy.vim

```lua
return {
    "AuroBreeze/quick-py",
    dependencies={
        "ahmedkhalf/project.nvim","neovim/nvim-lspconfig"
    },
    -- lazy =true,
    patterns = { "*.py" },
    config = function()
        require("quick-py").setup({})
    end
}
```
---

### packer.nvim

```lua
use { "AuroBreeze/quick-py", requires = { "ahmedkhalf/project.nvim", "neovim/nvim-lspconfig" } }
```
## Configuration

```lua
opt = {
    venv_names = { ".venv", "venv" }, -- 虚拟环境名称
    runserver_cmd = nil, -- 运行自定义python命令 ，例如django： python manage.py runserver
}

```

## Plugins

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
> 这个插件仅有不到200行代码，是我不到一个上午写出来的，如果这个插件有问题，希望大家能够指出或修复，感谢。

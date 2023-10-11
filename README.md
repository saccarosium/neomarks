> **Important**
> All the credits for the idea for the plugin goes to [ThePrimegean][1] and his
> plugin [harpoon][2]. I highly suggest you to watch is [vimconf video][3] to
> understand the usage of this plugin.

> **Warning**
> This plugin is not stable. Is expected changes in the API. If you experience bugs open an issue

<div align='center'>

# Neomarks

A new take on vim marks.

</div>

## Goals

* No opt-out dependencies
* Take advantage of native neovim features

## Non Goals

* Feature compatible with harpoon
* Support anything other than marking file

## Why

[Harpoon][2] is great and all but as a lot of features that I don't really need
and depends on `plenary.nvim`. This plugin focus on minimalism, do the minimum
set of features to be usable and use only neovim standard functions.

## Installation

Using your favorite Package manager:

```
"saccarosium/neomarks"
```

Put it directly in your config:

```sh
curl https://raw.githubusercontent.com/saccarosium/neomarks/main/lua/neomarks.lua -o "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim/lua/neomarks.lua
```

## Setup

Call the `setup` function (the following are the defaults):

```lua
require("neomarks").setup({
  storagefile = vim.fn.stdpath('data') .. "/neomarks.json",
  menu = {
    title = "Neomarks",
    title_pos = "center",
    border = "rounded",
    width = 60,
    height = 10,
  }
})
```

Now you can remap as you wish the following functions:

```lua
require("neomarks").mark_file() -- Mark file
require("neomarks").menu_toggle() -- Toggle the UI
require("neomarks").jump_to(<number>) -- Jump to specific index
```

### Branch specific marks

> **Note**
> For enabling branch specific files you need to: or install some sort of git integration plugin, that exposes a function to get the current branch name, or build a function on your own. It is preferable to achive this using a plugin. Some options are: [gitsigns.nvim][4] or [vim-fugitive][5].

To enable the feature you need to pass a function that returns the current branch name.

```lua
git_branch = vim.fn["FugitiveHead"], -- For vim-fugitive
git_branch = function() return vim.api.nvim_buf_get_var(0, "gitsigns_head") end, -- For gitsigns.nvim
git_branch = function() ... end, -- For custom function that returns branch name
```

## Roadmap

- [x] Support branch specific marks
- [ ] Mark specific buffer symbol using tree-sitter

## UI Mappings

| Keys | Action |
| :--- | :----- |
| `<CR>`, `e`, `E` | edit file under the cursor |
| `<C-c>`, `<ESC>`, `q` | close UI |


[1]: https://github.com/ThePrimeagen
[2]: https://github.com/ThePrimeagen/harpoon
[3]: https://www.youtube.com/watch?v=Qnos8aApa9g
[4]: https://github.com/lewis6991/gitsigns.nvim
[5]: https://github.com/tpope/vim-fugitive

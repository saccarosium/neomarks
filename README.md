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

## Why

[Harpoon][2] is great and all but as a lot of features that I don't really need
and depends on `plenary.nvim`. This plugin focus on minimalism, do the minimum
set of features to be usable and use only neovim standard functions.

## Quickstart

### Installation

Using your favorite Package manager:

```
"saccarosium/neomarks"
```

Put it directly in your config:

```sh
curl https://raw.githubusercontent.com/saccarosium/neomarks/main/lua/neomarks.lua -o "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim/lua/neomarks.lua
```

### Setup

Call the `setup` function (the following are the defaults):

```lua
require("neomarks").setup({
  storagefile = vim.fn.stdpath('data') .. "/neomarks.json",
  ui = {
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
require("neomarks").ui_toogle() -- Toggle the UI
require("neomarks").jump_to(<number>) -- Jump to specific index
```

## UI Mappings

| Keys | Action |
| :--- | :----- |
| `<CR>`, `e` | edit file under the cursor |
| `s`, `o`, `O` | edit file under the cursor in a horizontal split |
| `v`, `a`, `A` | edit file under the cursor in a vertical split |
| `<C-c>`, `<ESC>`, `q` | close UI |


[1]: https://github.com/ThePrimeagen
[2]: https://github.com/ThePrimeagen/harpoon
[3]: https://www.youtube.com/watch?v=Qnos8aApa9g

# breadcrumbs.nvim

Tiny Neovim plugin that leaves a short-lived breadcrumb trail behind your cursor using virtual text. Helpful if you frequently "lose" your cursor while editing.

## Features

- Fading trail of colored blocks where your cursor just was
- Uses extmarks + virtual text
- Automatic cleanup per buffer

![breadcrumbs.nvim demo](assets/breadcrumbs-demo.gif)

## Installation

Using lazy.nvim:

```lua
{
  "yourname/breadcrumbs.nvim",
  config = function()
    require("beaus_plugins.breadcrumb_trail").setup()
  end,
}
```

## Why

With ADHD, I often lose my cursor context when I move around a file.
The breadcrumb trail makes it obvious where I just was and keeps my focus intact.

## TODO
- Configurable colors and fade time
- Toggle command or keymap

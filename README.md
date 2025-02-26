# Flotsam

Flotsam is a simple Neovim plugin that allows you to open a floating terminal window, send a command to it, interact with the terminal, and close it easily with `<Esc><Esc>`.

## Features

- Opens a floating terminal in Neovim.
- Sends a command to the terminal on startup.
- Allows full interaction with the terminal.
- Closes the terminal with `<Esc><Esc>`.

## Installation

Using **lazy.nvim**:

```lua
{
    "carldaws/flotsam",
    config = function()
        require("flotsam").setup({
            mappings = {
                { keymap = "<leader>t", command = "htop" },
                { keymap = "<leader>g", command = "lazygit" },
            }
        })
    end
}
```

Using **packer.nvim**:

```lua
use {
    "carldaws/flotsam",
    config = function()
        require("flotsam").setup({
            mappings = {
                { keymap = "<leader>t", command = "htop" },
                { keymap = "<leader>g", command = "lazygit" },
            }
        })
    end
}
```

## Usage

You can manually open a floating terminal with:

```lua
:lua require("flotsam").open_floating_terminal("htop")
```

To automatically map keys to commands, configure Flotsam in your `setup` function:

```lua
require("flotsam").setup({
    mappings = {
        { keymap = "<leader>t", command = "htop" },
        { keymap = "<leader>g", command = "lazygit" },
    }
})
```

Now, pressing `<leader>t` will open a floating terminal running `htop`, and `<leader>g` will open `lazygit`.

### Closing the Terminal

Press `<Esc><Esc>` to close the floating terminal.

## Configuration Options

Flotsam currently supports the following options:

- `mappings`: A list of key mappings, where each mapping contains:
  - `keymap`: The keybinding to trigger the terminal.
  - `command`: The command to execute in the terminal.

## License

This project is licensed under the MIT License.

## Contributions

Contributions are welcome! Feel free to open an issue or a pull request.

---

Enjoy Flotsam! 🚀


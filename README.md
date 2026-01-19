# EZpoon 🪝

A very small, dead-simple Harpoon-like tool with minimal configuration but with
all the functionality you need!

- Inspired from ThePrimeagen's
  [Harpoon2](https://github.com/ThePrimeagen/harpoon/tree/harpoon2)
- ~ small: only 147 lines of Lua code (not counting comments and blank lines)

<img width="999" height="682" alt="image" src="https://github.com/user-attachments/assets/d8ebbc6b-7c77-45ec-894d-3e0e9cc9de04" />


## Table of Contents

1. [Motivation](#motivation)
2. [Why use something like Harpoon?](#why-use-something-like-harpoon)
3. [Features and Usage](#features-and-usage)
4. [Installation](#installation)
5. [Full Config](#full-config)
6. [APIs](#apis)

## Motivation

You might be wondering: "If Harpoon2 is already great, why use EZpoon?"

EZpoon isn't meant to compete with feature-rich plugins; it's meant to be simple
and disappear into your config. I built this for myself who want to reduce my
plugin footprint and want to know exactly how my tool works.

Some other reasons:

- No complex caching logic or heavy dependencies. Just 147 lines of transparent
  Lua.

- Only a single `init.lua` file and you can read the entire source code in a
  single sitting.

- Leverages Neovim's built-in floating windows, namespaces, and autocommands
  rather than custom UI layers.

Note: If you are looking for something more featureful or customisable, I
recommend [Harpoon2](https://github.com/ThePrimeagen/harpoon/tree/harpoon2).
This plugin's only value is that it is dead simple such that you can easily read
and understand the source code, and figure out what this tool is doing. You can
even copy the source code into your config, and truly make this functionality
yours (and I really encourage it!).

## Why use something like Harpoon?

ThePrimeagen has made a
[video](https://youtu.be/Qnos8aApa9g?si=ArMZu05hkdEEjGEW) summarising why, but I
will briefly explain here.

During development, you will often only be interacting with a handful of files
at any point in time.

For e.g., you are working on `File A`, but often jump to `File B` as there is
where you store your helper functions, but you will also jump to `File C` as
there is where you write your configuration files or environment variables. But
at any point in time, you will only be interacting with roughly less than 5
files.

What you want is a keymap that you can just press and then jump to that file
immediately, without opening a file picker or manually entering the filepath.
However, the keymap must be flexible and easily changed, you can't be always
jumping to your config to set keymaps to manually define specific filepaths.
That is too tedious and timeconsuming considering you might be constantly
changing your current set of working files!

Some pros and cons of native alternatives:

1. Global Marks `:h mark-motions`:
   - **Pros**:
     - Persistence across separate sessions
   - **Cons**:
     - Always jumping to specific location where you have marked it. But often
       times, when you jump back to the file, you want the cursor to be at where
       u last left the file.
     - As a result, you constantly need to remark the file which is troublesome,
       and runs the risk of u re-marking the wrong mark (e.g. mark to B instead
       of A (intended))
2. Arglist `:h arglist`:
   - **Pros**:
     - Remembers where you left the file with a `BufReadPost` autocmd.
   - **Cons**:
     - No persistence across sessions. If you exit neovim, all your previously
       set arglist disappears.
     - Difficult to manipulate the arglist and once manipulated, it can be
       difficult to jump accurately to the right file (i.e. `[count]argument`).

## Features and Usage

1. Easily add current file to a keymap.
2. Easily press your defined keymap to jump to a file.
3. Easily add/remove/edit keymaps and filepaths through an editable buffer,
   similar to [oil.nvim](https://github.com/stevearc/oil.nvim).
4. Git-local keymaps and files, or fallback to a global one if not in a git
   directory (i.e. Specific tagged files and keymaps for each git repo).

For my own config, I have defined a prefix as `<leader>m`.

**Adding File to Keymap** To add a current file to a keymap, I defined it as
`<leader>ma[some-character]`, in which I add the `a` (mnemonic for add) to the
prefix.

For example, to add the current file to a keymap that I will assign to `1`, I
will do `<leader>ma1`. If I want to map another file to `2`, I will
`:e anotherfile.txt`, and then do `<leader>ma2` to add that file to the keymap.

**Jumping to a File** Using the above-defined keymaps, if I want to jump to the
first file, I will just press `<leader>m1`, and to jump to the second file, I
will just press `<leader>m2`.

**Opening the Editable Menu** To open the editable menu, I will press
`<leader>mm`.

When editing the menu, you must ensure you follow this syntax
`[key] = valid-filepath` in order for the tagging to succeed. Otherwise, EZpoon
will throw an error and not save your changes. Lines with issues will be shown
with an extmark `X`.

It is also important to note that when entering `valid-filepath`, the file must exists!

**Menu**

<img width="1705" height="941" alt="image" src="https://github.com/user-attachments/assets/185f40c0-b240-4a55-9409-9b1f842d4933" />

**Menu with issues**

<img width="1561" height="833" alt="image" src="https://github.com/user-attachments/assets/93010aba-c9cc-46e4-940e-61039683d292" />


Note: These are my keybinds, and you are encouraged to set your own.

## Installation

<details>
  <summary>lazy.nvim</summary>

```lua
{
  'xavierchen0/ezpoon',
  config = function()
    local ez = require("ezpoon")
    -- Add your basic setup here (see below for full config)
  end
}
```

</details>

<details>
  <summary>Neovim native package</summary>

```sh
git clone --depth=1 https://github.com/xavierchen0/ezpoon.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/pack/ezpoon/start/ezpoon
```

or

```lua
vim.pack.add({
  { src = "https://github.com/xavierchen0/ezpoon" },
})
```

</details>

## Full Config

```lua
local ez = require("ezpoon")
-- Typically, you want to keep this to a small number as you are usually
-- interacting with a small set of working files
local valid_keys = {
  "0", "1", "2", "3", "4", "5",
}
-- or if you want to use all keys
-- local valid_keys = {
--   "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
--   "a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
--   "k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
--   "u", "v", "w", "x", "y", "z",
-- }

local prefix = "<leader>m"

for _, key in ipairs(valid_keys) do
  -- Add the keymaps to jump to a file
  vim.keymap.set("n", prefix .. key, function()
    ez.jump(key)
  end, { desc = "EZpoon: Jump to [" .. key .. "]" })

  -- Add the keymaps to add a file
  vim.keymap.set("n", prefix .. "a" .. key, function()
    ez.add(key)
  end, { desc = "EZpoon: Add current file to [" .. key .. "]" })
end

-- Opens the editable menu
vim.keymap.set("n", prefix .. "m", function()
  ez.menu()
end, { desc = "EZpoon: Open editable menu" })

-- Optional: Autocmd to return to last position in a file
-- Useful when you just launch nvim, and you used your defined keymaps to jump
-- to a file. Otherwise, when you first jump, your cursor will be at the top
-- of the file.
-- vim.api.nvim_create_autocmd("BufReadPost", {
--   desc = "Go to last edit location when opening a new buffer",
--   pattern = "*",
--   callback = function(event)
--     local exclude = { "gitcommit" }
--     local buf = event.buf
--
--     -- Check if filetype is excluded or if we've already jumped
--     if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc_flag then
--       return
--     end
--
--     -- Mark this buffer as processed so we don't jump every time we re-enter it
--     vim.b[buf].last_loc_flag = true
--
--     local mark = vim.api.nvim_buf_get_mark(buf, '"')
--     local lcount = vim.api.nvim_buf_line_count(buf)
--
--     -- If the mark is valid (between line 1 and the end of the file)
--     if mark[1] > 0 and mark[1] <= lcount then
--       pcall(vim.api.nvim_win_set_cursor, 0, mark)
--     end
--   end,
-- })

-- Optional: use " " (space) as leader key
-- vim.g.mapleader = " "
```

## APIs

EZpoon exposes a raw Lua table. There is no `setup()` function required; simply
`require` the module and call the functions.

### `require("ezpoon").add(key)`

Assigns the **current buffer's file path** to the specified slot.

- **key** (`string`): The slot identifier (e.g., `"a"`, `"1"`).

### `require("ezpoon").jump(key)`

Navigates to the file stored in the specified slot.

- **key** (`string`): The slot identifier.

### `require("ezpoon").menu()`

Opens the **Floating Management Window** to view, edit, or delete slots.

- **No parameters**

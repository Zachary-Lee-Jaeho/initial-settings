require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- {{{ disable arrow keys
-- please use hjkl !!!!
map("", "<up>", "<nop>", { noremap = true })
map("", "<down>", "<nop>", { noremap = true })
map("i", "<up>", "<nop>", { noremap = true })
map("i", "<down>", "<nop>", { noremap = true })
-- }}}

-- {{{ Define the kaymappings
map("n", "<C-e>", "3<C-e>", { noremap = true, silent = true })
map("n", "<C-y>", "3<C-y>", { noremap = true, silent = true })
map("n", "<C-_>", "gcc", { remap = true, silent = true, desc = "Toggle comment line" })
map("x", "<C-_>", "gc", { remap = true, silent = true, desc = "Toggle comment (visual)" })
-- }}}

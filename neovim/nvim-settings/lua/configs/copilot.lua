local copilot = require "copilot"

-- Disable the default keymap for <A-Tab>
vim.api.nvim_set_keymap("i", "<A-Tab>", "<Nop>", { noremap = true, silent = true })

copilot.setup {
  suggestion = {
    enabled = true,
    auto_trigger = true,
    dobounce = 50,
    keymap = {
      accept = "<A-Tab>",
      next = "<A-]>",
      prev = "<A-[>",
      detail = "<A-?>",
    },
  },
}

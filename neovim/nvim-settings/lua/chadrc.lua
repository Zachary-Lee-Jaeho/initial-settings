-- @type ChadrcConfig

-- This file  needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

local M = {}

M.ui = {
  theme = "jellybeans",
  changed_themes = {
    jellybeans = {
      base_30 = {
        grey = "#424242",
        grey_fg = "#606060",
      },
    },
  },

  nvdash = {
    load_on_startup = true,
  },

  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
}

return M

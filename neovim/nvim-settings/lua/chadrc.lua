-- @type ChadrcConfig

-- This file  needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

local M = {}

M.ui = {
  -- CUSTOMIZATION -------------
  theme = "jellybeans",
  changed_themes = {
    jellybeans = {
      base_30 = {
        grey = "#424242",
        grey_fg = "#515151",
      },
    },
  },

  nvdash = {
    load_on_startup = true,
  },
  -- CUSTOMIZATION -------------

  -- hl_override = {
  -- 	Comment = { italic = true },
  -- 	["@comment"] = { italic = true },
  -- },
}

M.plugins = "plugins"

require "functions"

return M

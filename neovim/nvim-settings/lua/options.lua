require "nvchad.options"

local o = vim.opt
o.whichwrap = ""
o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.smartindent = true
o.mouse = ""

o.termguicolors = true
o.emoji = false

o.clipboard = "unnamedplus"

-- Add more custom options here (if you need!)

local lsp_highlight = {
  LspTypeComment = { link = "Comment" },

  LspTypeDecorator = { link = "Special" },

  LspTypeMacro = { link = "Macro" },

  LspTypeNamespace = { link = "Include" },

  LspTypeMethod = { link = "Function" },
  LspTypeFunction = { link = "Function" },

  LspTypeEnumMember = { link = "Constant" },
  LspTypeParameter = { link = "Constant" },

  LspTypeProperty = { link = "Identifier" },

  LspTypeClass = { link = "Type" },
  LspTypeEnum = { link = "Type" },
  LspTypeStruct = { link = "Type" },
  LspTypeType = { link = "Type" },
  LspTypeInterface = { link = "Type" },
  LspTypeTypeParameter = { link = "Type" },

  LspTypeVariable = { link = "Variable" },
}

for group, conf in pairs(lsp_highlight) do
  vim.api.nvim_set_hl(0, "@lsp.type." .. group:sub(8), conf)
end

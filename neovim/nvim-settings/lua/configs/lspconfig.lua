local configs = require "nvchad.configs.lspconfig"
local on_attach = configs.on_attach
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"
local servers = {
  "pyright",
  "tsserver",
  "rust_analyzer",
  "clangd",
  "cmake",
  "jsonls",
  "bashls",
}

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

lspconfig.lua_ls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = {
        -- `vim` 전역 변수에 대한 경고를 억제
        globals = { "vim" },
      },
    },
  },
}

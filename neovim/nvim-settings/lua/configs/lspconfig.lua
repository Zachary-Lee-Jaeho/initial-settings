local configs = require "nvchad.configs.lspconfig"
local on_attach = configs.on_attach
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"
local servers = {
  "pyright",
  "biome",
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

lspconfig.clangd.setup {
  filetypes = { "c", "cpp", "objc", "objcpp", "tpp" },
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    client.server_capabilities.hoverProvider = true
  end,
  capabilities = capabilities,
}

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

-- 기존 매핑 복원
local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
vim.api.nvim_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
vim.api.nvim_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
vim.api.nvim_set_keymap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>sh", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", opts)

-- NvChad에서 제거한 LSP 관련 매핑 복원
vim.api.nvim_set_keymap(
  "n",
  "<leader>lf",
  "<cmd>lua vim.diagnostic.open_float()<CR>",
  { desc = "lsp floating diagnostics" }
)
vim.api.nvim_set_keymap("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { desc = "lsp prev diagnostic" })
vim.api.nvim_set_keymap("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", { desc = "lsp next diagnostic" })
vim.api.nvim_set_keymap(
  "n",
  "<leader>ds",
  "<cmd>lua vim.diagnostic.setloclist()<CR>",
  { desc = "lsp diagnostic loclist" }
)

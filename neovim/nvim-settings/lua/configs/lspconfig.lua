-- NvChad에서 on_attach/capabilities 재사용
local configs = require("nvchad.configs.lspconfig")
local on_attach = configs.on_attach
local capabilities = configs.capabilities

-- 공통 서버들
local servers = {
  "pyright",
  "biome",
  "rust_analyzer",
  "clangd",
  "neocmake",
  "jsonls",
  "bashls",
  "texlab",
  "marksman",
  "lua_ls",
}

-- 1) (선택) 서버별 커스텀을 사전에 등록: vim.lsp.config('<name>', { ... })
--    nvim-lspconfig의 기본 설정에 아래 항목이 병합됩니다.
vim.lsp.config("texlab", {
  filetypes = { "tex", "bib" },
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    client.server_capabilities.hoverProvider = true
  end,
  capabilities = capabilities,
})

vim.lsp.config("clangd", {
  filetypes = { "c", "cpp", "objc", "objcpp", "tpp" },
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    client.server_capabilities.hoverProvider = true
  end,
  capabilities = capabilities,
})

vim.lsp.config("lua_ls", {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    Lua = { diagnostics = { globals = { "vim" } } },
  },
})

-- 2) 공통 훅/캡 능력을 나머지 서버에 적용
for _, name in ipairs(servers) do
  -- 이미 위에서 개별 config 넣은 서버는 다시 호출해도 병합만 됩니다.
  vim.lsp.config(name, {
    on_attach = on_attach,
    capabilities = capabilities,
  })
  -- 3) 실제 활성화
  vim.lsp.enable(name)
end

-- 키맵은 최신 API로 갱신 권장(동작은 동일)
local map = vim.keymap.set
local opts = { noremap = true, silent = true }
map("n", "gD", vim.lsp.buf.declaration, opts)
map("n", "gd", vim.lsp.buf.definition, opts)
map("n", "K",  vim.lsp.buf.hover, opts)
map("n", "gi", vim.lsp.buf.implementation, opts)
map("n", "<leader>sh", vim.lsp.buf.signature_help, opts)
map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
map("n", "<leader>lf", vim.diagnostic.open_float, { desc = "lsp floating diagnostics" })
map("n", "[d", vim.diagnostic.goto_prev,          { desc = "lsp prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next,          { desc = "lsp next diagnostic" })
map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "lsp diagnostic loclist" })


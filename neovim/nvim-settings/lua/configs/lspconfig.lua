local configs = require "nvchad.configs.lspconfig"
local on_attach = configs.on_attach
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"
local servers = {
  "pyright",
  "tsserver",
  "rust_analyzer",
  "jsonls",
  "bashls",
  "cmake",
}

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

lspconfig["clangd"].setup {
  on_attach = on_attach,
  capabilities = capabilities,
  handlers = {
    -- {{{ surpress diagnostics }}}
    -- ["textDocument/publishDiagnostics"] = function() end,
  },
}

lspconfig["lua_ls"].setup {
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

local mlirConf = require "lspconfig.configs"
if not mlirConf.mlir_lsp then
  mlirConf.mlir_lsp = {
    default_config = {
      cmd = { "/media/ssd/jaeho/llvmVersions/core-dnn/llvm-project/build/bin/mlir-lsp-server" },
      root_dir = lspconfig.util.root_pattern ".git",
      filetypes = { "mlir" },
    },
  }
end
if not mlirConf.tblgen_lsp then
  mlirConf.tblgen_lsp = {
    default_config = {
      root_dir = lspconfig.util.root_pattern ".git",
      cmd = {
        "/media/ssd/jaeho/llvmVersions/core-dnn/llvm-project/build/bin/tblgen-lsp-server",
        "--tablegen-compilation-database=./tablegen_compile_commands.yml",
      },
      filetypes = { "tablegen" },
    },
  }
end
-- tblgen-lsp-server

lspconfig.mlir_lsp.setup {
  settings = {
    diagnostics = {
      enable = false,
    },
  },
}

lspconfig.tblgen_lsp.setup {
  settings = {
    diagnostics = {
      enable = false,
    },
  },
}

-- Without the loop, you would have to manually set up each LSP
--
-- lspconfig.html.setup {
--   on_attach = on_attach,
--   capabilities = capabilities,
-- }
--
-- lspconfig.cssls.setup {
--   on_attach = on_attach,
--   capabilities = capabilities,
-- }

local conform = require "conform"

conform.setup {
  formatters_by_ft = {
    lua = { "stylua" },
    -- Use a sub-list to run only the first available formatter
    javascript = { { "prettierd", "prettier" } },
    cpp = { "clang_format" },
    python = { "black" },
  },
  format_on_save = {
    timeout_ms = 1000,
    lsp_fallback = true,
  },
  format_after_save = {
    lsp_fallback = true,
  },
}

conform.formatters.clang_format = {
  prepend_args = {
    "-style={BasedOnStyle: WebKit, AlignTrailingComments: true, IndentWidth: 2, TabWidth: 2, UseTab: Never}",
  },
}

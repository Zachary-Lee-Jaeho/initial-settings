local plugins = {
  {
    "github/copilot.vim",
    config = function()
      require "configs.copilot"
    end,
    lazy = false,
  },
  {
    "p00f/clangd_extensions.nvim",
    config = function()
      require "configs.clangd_extensions"
    end,
  },
  {
    "stevearc/conform.nvim",
    config = function()
      require "configs.conform"
    end,
    lazy = false,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "nvchad.configs.lspconfig"
      require "configs.lspconfig"
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "clang-format",
        "clangd",
        "stylua",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- defaults
        "vim",
        "lua",

        -- web dev
        "html",
        "css",
        "javascript",
        "json",
        -- "vue", "svelte",

        -- Coding
        "c",
        "cpp",
        "cuda",
        "cmake",
        "python",

        "gitignore",
        "llvm",
      },
    },
  },
}

return plugins

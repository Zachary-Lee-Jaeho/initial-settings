return {
  "nvim-lua/plenary.nvim",
  { "nvim-tree/nvim-web-devicons", lazy = true },

  {
    "nvchad/ui",
    config = function()
      require "nvchad"
    end,
  },

  {
    "nvchad/base46",
    lazy = true,
    build = function()
      require("base46").load_all_highlights()
    end,
  },
  "nvchad/volt", -- optional, needed for theme switcher
  -- or just use Telescope themes
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
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
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- Bash
        "bash-language-server",
        "beautysh",
        "shellcheck",

        -- C/C++
        "clangd",
        "clang-format",

        --Lua
        "lua-language-server",
        "stylua",

        -- Python
        "debugpy",
        "mypy",
        "ruff-lsp",
        "pyright",
        "python-lsp-server",
      },
    },
  },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require "configs.copilot"
    end,
    lazy = false,
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

        -- Coding
        "c",
        "cpp",
        "cuda",
        "cmake",
        "python",

        "gitignore",
        "llvm",
      },
      indent = {
        enable = true,
      },
    },
  },
}

return {
  { "mason-org/mason.nvim", lazy = false, opts = {} },

  -- Language servers / debuggers installed automatically
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false,
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = {
        "jdtls",
        "java-debug-adapter",
        "java-test",
        "lua-language-server",
        "typescript-language-server",
        "angular-language-server",
        "html-lsp",
        "css-lsp",
        "json-lsp",
        "yaml-language-server",
        "lemminx",
        "bash-language-server",
        "prettier",
        "stylua",
      },
    },
  },

  {
    "mason-org/mason-lspconfig.nvim",
    lazy = false,
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false } } },
      })
      -- jdtls is started by nvim-jdtls (plugins/java.lua)
      require("mason-lspconfig").setup({ automatic_enable = { exclude = { "jdtls" } } })

      vim.diagnostic.config({
        severity_sort = true,
        virtual_text = { spacing = 2 },
        float = { border = "rounded" },
      })
    end,
  },

  -- Reformat code
  {
    "stevearc/conform.nvim",
    cmd = "ConformInfo",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
      },
      default_format_opts = { lsp_format = "fallback" },
    },
  },

  -- Code completion
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "enter",
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<Tab>"] = { "select_and_accept", "fallback" },
        -- Menu open: move in the menu; else AI suggestion shown: cycle it; else EditorDown/Up
        ["<A-j>"] = { "select_next", function() return require("util").cycle_ai_suggestion(1) end, "fallback" },
        ["<A-k>"] = { "select_prev", function() return require("util").cycle_ai_suggestion(-1) end, "fallback" },
      },
      completion = { documentation = { auto_show = true } },
      signature = { enabled = true }, -- Parameter info
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },

  -- Syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        "java", "kotlin", "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml", "xml", "sql",
        "html", "css", "scss", "javascript", "typescript", "tsx", "angular", "markdown",
        "markdown_inline", "dockerfile", "groovy", "properties", "gitcommit", "diff",
      })
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
}

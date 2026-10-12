return {
  -- Gruvbox Dark Hard (IntelliJ colour scheme)
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("gruvbox").setup({ contrast = "hard" })
      vim.cmd.colorscheme("gruvbox")
    end,
  },
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- Editor tabs
  {
    "akinsho/bufferline.nvim",
    version = "*",
    lazy = false,
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        close_command = function(buf)
          require("util").close_buffer(buf)
        end,
        offsets = { { filetype = "NvimTree", text = "Project", highlight = "Directory", text_align = "left" } },
      },
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = { options = { theme = "gruvbox", globalstatus = true } },
  },

  -- set which-key
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 0,
      spec = {
        { "<leader>a", group = "run / debug" },
        { "<leader>g", group = "git" },
        { "<leader>r", group = "refactor" },
      },
    },
  },

  -- Rainbow Brackets
  { "HiPhish/rainbow-delimiters.nvim", lazy = false },
  -- Indent guides
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", event = { "BufReadPost", "BufNewFile" }, opts = {} },
  -- Background task / indexing progress
  { "j-hui/fidget.nvim", event = "LspAttach", opts = {} },
  -- Problems tool window
  { "folke/trouble.nvim", cmd = "Trouble", opts = {} },
}

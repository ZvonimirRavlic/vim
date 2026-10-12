-- Popular additions beyond the IntelliJ mirror. Keys are listed in NEOVIM.md ("Extras").
return {
  -- Sticky method/class signature at the top while scrolling (IntelliJ "sticky lines")
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = { max_lines = 3 },
  },

  -- Code text objects and motions: daf, vic, ]m ...
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })
      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local objects = {
        af = "@function.outer", ["if"] = "@function.inner",
        ac = "@class.outer", ic = "@class.inner",
        aa = "@parameter.outer", ia = "@parameter.inner",
      }
      for lhs, query in pairs(objects) do
        vim.keymap.set({ "x", "o" }, lhs, function()
          select.select_textobject(query, "textobjects")
        end, { desc = query })
      end
      local motions = {
        ["]m"] = { move.goto_next_start, "@function.outer", "Next method" },
        ["[m"] = { move.goto_previous_start, "@function.outer", "Previous method" },
        ["]M"] = { move.goto_next_end, "@function.outer", "Next method end" },
        ["[M"] = { move.goto_previous_end, "@function.outer", "Previous method end" },
        ["]c"] = { move.goto_next_start, "@class.outer", "Next class" },
        ["[c"] = { move.goto_previous_start, "@class.outer", "Previous class" },
      }
      for lhs, m in pairs(motions) do
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          m[1](m[2], "textobjects")
        end, { desc = m[3] })
      end
    end,
  },

  -- TODO / FIXME highlighting and list (IntelliJ TODO tool window)
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      { "<leader>n", "<cmd>TodoTelescope<cr>", desc = "TODOs" },
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous TODO" },
    },
  },

  -- Undo history tree (roughly IntelliJ Local History)
  {
    "mbbill/undotree",
    keys = { { "<leader>U", "<cmd>UndotreeToggle<cr>", desc = "Undo history" } },
  },

  -- Edit the file system as a buffer; `-` opens the current file's folder
  {
    "stevearc/oil.nvim",
    lazy = false,
    opts = { default_file_explorer = false, view_options = { show_hidden = true } },
    keys = { { "-", "<cmd>Oil<cr>", desc = "Open parent folder (oil)" } },
  },

  -- Pinned files (IntelliJ bookmarks)
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("harpoon"):setup()
    end,
    keys = {
      { "<leader>ba", function() require("harpoon"):list():add() end, desc = "Pin file" },
      { "<leader>bb", function() local h = require("harpoon") h.ui:toggle_quick_menu(h:list()) end, desc = "Pinned files" },
      { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Pinned file 1" },
      { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Pinned file 2" },
      { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Pinned file 3" },
      { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Pinned file 4" },
    },
  },

  -- Start screen when there's no session to restore
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { icon = " ", key = "f", desc = "Find file", action = ":lua require('telescope.builtin').find_files()" },
            { icon = " ", key = "r", desc = "Recent files", action = ":lua require('telescope.builtin').oldfiles({ cwd_only = true })" },
            { icon = " ", key = "g", desc = "Find in path", action = ":lua require('telescope.builtin').live_grep()" },
            { icon = " ", key = "s", desc = "Restore session", action = ":lua require('persistence').load()" },
            { icon = " ", key = "c", desc = "Config", action = ":lua require('telescope.builtin').find_files({ cwd = vim.fn.stdpath('config') })" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
    },
  },

  -- Nicer command line and messages
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      lsp = {
        progress = { enabled = false }, -- fidget shows LSP progress
        signature = { enabled = false }, -- blink.cmp shows signatures
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
      },
      presets = { command_palette = true, long_message_to_split = true, lsp_doc_border = true },
    },
  },

  -- AI inline completion (Codeium/Windsurf, as in IntelliJ). Run :Codeium Auth once.
  -- Tab: completion menu open -> blink accepts; AI suggestion shown -> accept it; else a normal tab.
  {
    "Exafunction/windsurf.nvim",
    event = "InsertEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("codeium").setup({
        enable_cmp_source = false,
        virtual_text = {
          enabled = true,
          key_bindings = { accept = "<Tab>", next = "<M-]>", prev = "<M-[>", clear = "<C-]>" },
        },
      })
      local virtual_text = require("codeium.virtual_text")
      vim.keymap.set("i", "<C-l>", virtual_text.accept, { expr = true, silent = true, desc = "Accept AI suggestion" })
    end,
  },
}

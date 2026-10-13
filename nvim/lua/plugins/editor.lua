return {
  -- NERDTree / Project view (set NERDTreeShowHidden)
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      view = { width = 40 },
      filters = { dotfiles = false, git_ignored = false },
      renderer = { group_empty = true },
      actions = { open_file = { quit_on_open = false } },
      -- Default tree keys, plus l = open / expand and h = collapse / go to parent (hjkl only)
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        local default = (api.map and api.map.on_attach and api.map.on_attach.default) or api.config.mappings.default_on_attach
        default(bufnr)
        local function is_dir(node)
          return node ~= nil and node.nodes ~= nil
        end
        vim.keymap.set("n", "l", function()
          local node = api.tree.get_node_under_cursor()
          if not (is_dir(node) and node.open) then
            api.node.open.edit()
          end
        end, { buffer = bufnr, nowait = true, desc = "Open file / expand folder" })
        vim.keymap.set("n", "h", function()
          local node = api.tree.get_node_under_cursor()
          if is_dir(node) and node.open then
            api.node.open.edit()
          else
            api.node.navigate.parent_close()
          end
        end, { buffer = bufnr, nowait = true, desc = "Collapse folder / go to parent" })
      end,
    },
  },

  -- Search everywhere / Find in path / Recent files
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      telescope.setup({
        defaults = {
          layout_strategy = "horizontal",
          layout_config = { prompt_position = "top" },
          sorting_strategy = "ascending",
          file_ignore_patterns = { "%.git/", "node_modules/", "build/", "target/", "%.gradle/" },
          mappings = {
            -- IntelliJ: alt-k selects previous row in popups
            i = { ["<A-j>"] = actions.move_selection_next, ["<A-k>"] = actions.move_selection_previous },
          },
        },
        pickers = { find_files = { hidden = true } },
        extensions = { ["ui-select"] = { require("telescope.themes").get_dropdown() } },
      })
      telescope.load_extension("fzf")
      telescope.load_extension("ui-select")
    end,
  },

  -- set easymotion
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = { modes = { char = { enabled = false } } },
  },

  -- set surround
  { "kylechui/nvim-surround", version = "^3.0.0", event = "VeryLazy", opts = {} },

  -- IntelliJ auto-closes brackets and quotes
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

  -- Terminal tool window and run configurations
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec" },
    opts = { size = 15, shade_terminals = false, start_in_insert = true, persist_mode = false },
  },
}

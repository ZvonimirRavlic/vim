return {
  -- Reopen the project as you left it (files, splits, cursor), per working directory.
  -- Starting `nvim` with no arguments restores that folder's last session automatically.
  {
    "folke/persistence.nvim",
    lazy = false,
    opts = {},
    config = function(_, opts)
      -- Terminals and empty buffers can't be restored, keep them out of the session
      vim.opt.sessionoptions = { "buffers", "curdir", "folds", "help", "tabpages", "winsize" }
      require("persistence").setup(opts)

      local group = vim.api.nvim_create_augroup("session_restore", { clear = true })
      -- The project tree would come back as an empty window, so close it before saving
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "PersistenceSavePre",
        callback = function()
          pcall(vim.cmd, "NvimTreeClose")
        end,
      })
      vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        nested = true,
        callback = function()
          local persistence = require("persistence")
          if vim.fn.argc() == 0 and not vim.g.started_with_stdin and vim.fn.filereadable(persistence.current()) == 1 then
            persistence.load()
            -- The start screen was opened before the session loaded; drop it
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.bo[buf].filetype == "snacks_dashboard" then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
              end
            end
          end
        end,
      })
      vim.api.nvim_create_autocmd("StdinReadPre", {
        group = group,
        callback = function()
          vim.g.started_with_stdin = true
        end,
      })
    end,
  },
}

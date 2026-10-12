return {
  -- Gutter changes + GitToolBox inline blame
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = { current_line_blame = true },
  },
  -- Update project / Commit / Push
  { "tpope/vim-fugitive", cmd = { "Git", "G" } },
  -- Diff / file history
  { "sindrets/diffview.nvim", cmd = { "DiffviewOpen", "DiffviewFileHistory" } },
  -- LazyGit
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitCurrentFile", "LazyGitLog" },
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  -- GitHub pull request review in editor
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim", "nvim-tree/nvim-web-devicons" },
    opts = { picker = "telescope" },
  },
}

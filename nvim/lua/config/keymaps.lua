-- Mirrors ~/vim/.ideavimrc (IdeaVim) and the IntelliJ "macOS copy" keymap.
-- Every mapping has a desc so which-key shows it. Full table: ~/vim/NEOVIM.md
local map = vim.keymap.set
local util = require("util")
local run = require("util.run")

local function tb(picker, opts)
  return function()
    require("telescope.builtin")[picker](opts or {})
  end
end

-- Neovim defaults that clash with the IdeaVim `g` mappings below.
-- With `notimeout` a prefix map would wait forever, so remove them.
for _, lhs in ipairs({ "grn", "grr", "gri", "gra", "grt", "gcc" }) do
  pcall(vim.keymap.del, "n", lhs)
end
pcall(vim.keymap.del, "x", "gra")

---------------------------------------------------------------------------
-- .ideavimrc
---------------------------------------------------------------------------
map("n", "<leader>j", function() require("flash").jump() end, { desc = "EasyMotion jump" })

map("n", "<leader>t", function() require("util.terminal").toggle() end, { desc = "Terminal" })
map({ "n", "t" }, "<D-t>", function() require("util.terminal").new_tab() end, { desc = "New terminal tab" })
map("n", "<leader>T", function() require("util.terminal").new_tab() end, { desc = "New terminal tab" })
map("n", "<leader>v", function() util.move_to_new_split(true) end, { desc = "Move tab right (split)" })
map("n", "<leader>h", function() util.move_to_new_split(false) end, { desc = "Move tab down (split)" })
map("n", "<leader>u", "<cmd>only<cr>", { desc = "Unsplit" })
map("n", "<leader>m", util.move_to_opposite_group, { desc = "Move tab to opposite split" })

map("n", "<leader>s", function()
  vim.api.nvim_create_autocmd("InsertEnter", {
    once = true,
    callback = function()
      vim.schedule(function() require("blink.cmp").show() end)
    end,
  })
  vim.api.nvim_feedkeys("a", "n", false)
end, { desc = "Code completion" })

-- Split navigation (normal + terminal mode, like IntelliJ tool windows)
for key, dir in pairs({ h = "h", j = "j", k = "k", l = "l" }) do
  map("n", "<A-" .. key .. ">", "<C-w>" .. dir, { desc = "Window " .. dir })
  map("t", "<A-" .. key .. ">", [[<C-\><C-n><C-w>]] .. dir, { desc = "Window " .. dir })
end

-- PreviousTab / NextTab (also ctrl-left/right from the macOS copy keymap)
map("n", "<C-A-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous tab" })
map("n", "<C-A-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next tab" })
map("n", "<C-Left>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous tab" })
map("n", "<C-Right>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next tab" })

-- <c-o> / <c-i> Back / Forward: native jumplist, intentionally not remapped

-- CloseContent
map("n", "<D-w>", util.close_buffer, { desc = "Close tab" })
map("t", "<D-w>", [[<C-\><C-n><cmd>close<cr>]], { desc = "Hide tool window" })

map("n", "<esc>", "<cmd>noh<cr><esc>", { desc = "Clear highlight" })
map({ "n", "x" }, "<leader>l", util.format, { desc = "Reformat code" })
map("n", "<leader>o", util.organize_imports, { desc = "Optimize imports" })
map("n", "<leader>p", "<cmd>NvimTreeFindFile<cr>", { desc = "Select in project view" })

map("n", "<leader>e", tb("oldfiles", { cwd_only = true }), { desc = "Recent files" })
map("n", "<leader>f", tb("current_buffer_fuzzy_find"), { desc = "Find in file" })
map("n", "<leader>F", tb("live_grep"), { desc = "Find in path" })

map("n", "<leader>ar", run.run, { desc = "Run" })
map("n", "<leader>ad", function() require("dap").continue() end, { desc = "Debug / resume" })
map("n", "<leader>ac", run.select, { desc = "Run configurations" })
map("n", "<leader>as", run.stop, { desc = "Stop" })

map("n", "gi", tb("lsp_implementations"), { desc = "Goto implementation" })
map("n", "gs", util.goto_super, { desc = "Goto super method" })
map("n", "gu", util.goto_declaration, { desc = "Goto declaration / usages" })
map("n", "ge", function()
  vim.diagnostic.jump({ count = 1, severity = { min = vim.diagnostic.severity.WARN }, float = true })
end, { desc = "Next error" })
map("n", "gE", function()
  vim.diagnostic.jump({ count = -1, severity = { min = vim.diagnostic.severity.WARN }, float = true })
end, { desc = "Previous error" })
map("n", "gn", util.goto_class, { desc = "Goto class" })
map("n", "gc", util.goto_class, { desc = "Goto class" })
map("n", "gf", tb("find_files"), { desc = "Goto file" })
map("n", "gr", util.goto_related, { desc = "Goto related (test <-> class)" })

map("n", "<C-t>", "<cmd>NvimTreeToggle<cr>", { desc = "Project tree" })

map("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })

-- Refactorings
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>rm", function()
  if vim.bo.filetype == "java" then require("jdtls").extract_method() else util.code_action_matching("refactor.extract", "function") end
end, { desc = "Extract method" })
map("x", "<leader>rm", function()
  if vim.bo.filetype == "java" then require("jdtls").extract_method(true) else util.code_action_matching("refactor.extract", "function") end
end, { desc = "Extract method" })
map("n", "<leader>rv", function()
  if vim.bo.filetype == "java" then require("jdtls").extract_variable_all() else util.code_action_matching("refactor.extract", "variable") end
end, { desc = "Introduce variable" })
map("x", "<leader>rv", function()
  if vim.bo.filetype == "java" then require("jdtls").extract_variable_all(true) else util.code_action_matching("refactor.extract", "variable") end
end, { desc = "Introduce variable" })
map({ "n", "x" }, "<leader>rf", function() util.code_action_matching("refactor", "field") end, { desc = "Introduce field" })
map({ "n", "x" }, "<leader>rs", function() util.code_action_matching("refactor", "signature") end, { desc = "Change signature" })
map("n", "<leader>rc", util.code_cleanup, { desc = "Code cleanup" })
map({ "n", "x" }, "<leader>rr", function() vim.lsp.buf.code_action({ context = { only = { "refactor" }, diagnostics = {} } }) end, { desc = "Refactor this..." })

-- Git
map("n", "<leader>gu", "<cmd>Git pull<cr>", { desc = "Update project (pull)" })
map("n", "<leader>gb", tb("git_branches"), { desc = "Branches" })
map("n", "<leader>gc", "<cmd>Git<cr>", { desc = "Commit (status window)" })
map("n", "<leader>gp", "<cmd>Git push<cr>", { desc = "Push" })
map("n", "<leader>gr", "<cmd>Octo review start<cr>", { desc = "PR review in editor" })

---------------------------------------------------------------------------
-- IntelliJ keymap ("macOS copy" / "Windows Proper Redo") customisations
---------------------------------------------------------------------------
map("i", "<A-j>", "<Down>", { desc = "EditorDown" })
map("i", "<A-k>", "<Up>", { desc = "EditorUp" })
map("i", "<A-d>", "<C-o>dd", { desc = "Delete line" })

---------------------------------------------------------------------------
-- Extras (not in IntelliJ config, but needed / handy in a terminal)
---------------------------------------------------------------------------
map("n", "<leader>w", util.close_buffer, { desc = "Close tab (Cmd-W fallback)" })
map({ "n", "x" }, "<A-CR>", vim.lsp.buf.code_action, { desc = "Show intention actions" })
map("n", "<A-F7>", tb("lsp_references", { include_declaration = false }), { desc = "Find usages" })
map("n", "<S-F6>", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>/", function() return require("vim._comment").operator() .. "_" end, { expr = true, desc = "Comment line" })
map("n", "<D-/>", function() return require("vim._comment").operator() .. "_" end, { expr = true, desc = "Comment line" })
map("x", "<leader>/", "gc", { remap = true, desc = "Comment selection" })
map("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })
map("n", "<leader>gd", function()
  if require("diffview.lib").get_current_view() then
    vim.cmd("DiffviewClose")
  else
    vim.cmd("DiffviewOpen")
  end
end, { desc = "Diff working tree (toggle)" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "File history" })
map("n", "<leader>gl", "<cmd>Gitsigns blame_line<cr>", { desc = "Blame line" })
-- Hunks (changed blocks): j/k instead of ]h/[h, brackets are awkward on a Corne
map("n", "<leader>gj", function() require("gitsigns").nav_hunk("next") end, { desc = "Next change" })
map("n", "<leader>gk", function() require("gitsigns").nav_hunk("prev") end, { desc = "Previous change" })
map("n", "<leader>gv", function() require("gitsigns").preview_hunk() end, { desc = "Preview change" })
map("n", "<leader>gs", function() require("gitsigns").stage_hunk() end, { desc = "Stage / unstage change" })
map("n", "<leader>gx", function() require("gitsigns").reset_hunk() end, { desc = "Revert change" })
map("x", "<leader>gs", function()
  require("gitsigns").stage_hunk({ vim.fn.line("v"), vim.fn.line(".") })
end, { desc = "Stage selected lines" })
map("x", "<leader>gx", function()
  require("gitsigns").reset_hunk({ vim.fn.line("v"), vim.fn.line(".") })
end, { desc = "Revert selected lines" })
map("n", "<leader>x", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Problems" })
map("n", "<leader>?", tb("keymaps"), { desc = "Search keymaps" })
map("n", "<leader>,", tb("buffers"), { desc = "Open tabs" })
map("n", "<leader>.", tb("resume"), { desc = "Resume last search" })

-- Debugger (IntelliJ macOS keys)
map("n", "<leader>ab", function() require("persistent-breakpoints.api").toggle_breakpoint() end, { desc = "Toggle breakpoint" })
map("n", "<leader>ax", function() require("persistent-breakpoints.api").clear_all_breakpoints() end, { desc = "Remove all breakpoints" })
map("n", "<leader>aB", util.list_breakpoints, { desc = "All breakpoints" })
map("n", "<leader>ae", util.conditional_breakpoint, { desc = "Conditional breakpoint" })
map("n", "<leader>al", util.log_point, { desc = "Log point" })
map("n", "<leader>an", function() require("dap").step_over() end, { desc = "Step over (next)" })
map("n", "<leader>ai", function() require("dap").step_into() end, { desc = "Step into" })
map("n", "<leader>ao", function() require("dap").step_out() end, { desc = "Step out" })
map("n", "<F8>", function() require("dap").step_over() end, { desc = "Step over" })
map("n", "<F7>", function() require("dap").step_into() end, { desc = "Step into" })
map("n", "<S-F8>", function() require("dap").step_out() end, { desc = "Step out" })
map("n", "<F9>", function() require("dap").continue() end, { desc = "Resume" })
map("n", "<leader>au", function() require("dapui").toggle() end, { desc = "Debug UI" })

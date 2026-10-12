local group = vim.api.nvim_create_augroup("intellij", { clear = true })

-- Plug 'machakann/vim-highlightedyank'
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank({ timeout = 300 })
  end,
})

-- IntelliJ autosave: save when switching files and when the terminal loses focus
vim.api.nvim_create_autocmd("BufLeave", {
  group = group,
  callback = function(args)
    local bo = vim.bo[args.buf]
    if bo.modified and bo.buftype == "" and bo.modifiable and vim.api.nvim_buf_get_name(args.buf) ~= "" then
      vim.api.nvim_buf_call(args.buf, function()
        vim.cmd("silent! update")
      end)
    end
  end,
})
vim.api.nvim_create_autocmd("FocusLost", {
  group = group,
  command = "silent! wall",
})

-- IntelliJ "Synchronize files on frame activation"
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = group,
  command = "silent! checktime",
})

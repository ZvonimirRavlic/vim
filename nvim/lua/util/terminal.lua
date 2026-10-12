-- IntelliJ terminal tool window: a bottom panel with terminal tabs.
--   Space t       toggle the panel
--   Cmd T         new terminal tab (Space T without the WezTerm passthrough)
--   Ctrl Alt h/l  previous / next terminal tab (inside the panel)
--   Esc           focus the editor (FocusEditor)
local M = {}

local terms = {} -- terminal buffers, in tab order
local current = 0
local win = nil

-- Panel height is remembered across toggles and nvim restarts, like IntelliJ tool windows
local height_file = vim.fn.stdpath("state") .. "/terminal_height"
local height = tonumber(vim.fn.filereadable(height_file) == 1 and vim.fn.readfile(height_file)[1] or "") or 15

local function panel_open()
  return win ~= nil and vim.api.nvim_win_is_valid(win)
end

local function save_height()
  if not panel_open() then
    return
  end
  local h = vim.api.nvim_win_get_height(win)
  if h ~= height and h >= 3 then
    height = h
    vim.fn.writefile({ tostring(height) }, height_file)
  end
end

local function render_winbar()
  if not panel_open() then
    return
  end
  local parts = {}
  for i, _ in ipairs(terms) do
    local hl = i == current and "%#TabLineSel#" or "%#TabLine#"
    table.insert(parts, hl .. " Terminal " .. i .. " ")
  end
  vim.wo[win].winbar = table.concat(parts, "%#TabLineFill# ") .. "%#TabLineFill#"
end

local function show(idx)
  current = idx
  vim.api.nvim_win_set_buf(win, terms[idx])
  render_winbar()
  vim.api.nvim_set_current_win(win)
  vim.cmd.startinsert()
end

local function open_panel()
  if not panel_open() then
    vim.cmd("botright " .. height .. "split")
    win = vim.api.nvim_get_current_win()
    vim.wo[win].winfixheight = true
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
  end
end

local function create()
  open_panel()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.fn.jobstart(vim.o.shell, { term = true })
  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = "hide"

  local function opts(desc)
    return { buffer = buf, desc = desc }
  end
  vim.keymap.set("t", "<Esc>", [[<C-\><C-n><C-w>p]], opts("Focus editor"))
  for _, mode in ipairs({ "t", "n" }) do
    vim.keymap.set(mode, "<C-A-h>", function() M.cycle(-1) end, opts("Previous terminal tab"))
    vim.keymap.set(mode, "<C-A-l>", function() M.cycle(1) end, opts("Next terminal tab"))
    vim.keymap.set(mode, "<D-w>", function() vim.fn.jobstop(vim.bo[buf].channel) end, opts("Close terminal tab"))
  end

  table.insert(terms, buf)
  show(#terms)
end

local group = vim.api.nvim_create_augroup("terminal_tabs", { clear = true })

-- Remember the height whenever the panel is resized (mouse drag, :resize, Ctrl-w +/-)
vim.api.nvim_create_autocmd("WinResized", {
  group = group,
  callback = function()
    if panel_open() and vim.tbl_contains(vim.v.event.windows, win) then
      save_height()
    end
  end,
})

-- Shell exited: drop its tab, show a neighbour or close the panel
vim.api.nvim_create_autocmd("TermClose", {
  group = group,
  callback = function(args)
    local idx = nil
    for i, b in ipairs(terms) do
      if b == args.buf then
        idx = i
      end
    end
    if idx == nil then
      return
    end
    table.remove(terms, idx)
    if idx < current then
      current = current - 1
    end
    vim.schedule(function()
      if #terms == 0 then
        if panel_open() then
          vim.api.nvim_win_close(win, true)
        end
        current = 0
      elseif panel_open() and vim.api.nvim_win_get_buf(win) == args.buf then
        show(math.min(idx, #terms))
      else
        current = math.min(current, #terms)
        render_winbar()
      end
      pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
    end)
  end,
})

-- ActivateTerminalToolWindow
function M.toggle()
  if panel_open() then
    save_height()
    vim.api.nvim_win_close(win, false)
    return
  end
  if #terms == 0 then
    create()
  else
    open_panel()
    show(current)
  end
end

-- New terminal tab
function M.new_tab()
  create()
end

function M.cycle(delta)
  if #terms == 0 or not panel_open() then
    return
  end
  show((current - 1 + delta) % #terms + 1)
end

return M

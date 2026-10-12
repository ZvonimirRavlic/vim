-- Helpers that emulate IntelliJ editor/tab actions
local M = {}

local function is_editor_window(win)
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "NvimTree"
end

-- Another listed buffer to show in place of `buf` (prefers the alternate file)
local function other_listed(buf)
  local alt = vim.fn.bufnr("#")
  if alt > 0 and alt ~= buf and vim.bo[alt].buflisted then
    return alt
  end
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= buf and vim.bo[b].buflisted and vim.bo[b].buftype == "" then
      return b
    end
  end
  return nil
end

-- CloseContent (Cmd-W): close the tab but keep the split layout
function M.close_buffer(buf)
  if buf == nil or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  if vim.bo[buf].buftype ~= "" then
    -- Tool windows (terminal, tree, help...) just get hidden
    pcall(vim.cmd.close)
    return
  end
  if vim.bo[buf].modified and vim.api.nvim_buf_get_name(buf) ~= "" then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("silent! write")
    end)
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    local other = vim.api.nvim_win_call(win, function()
      return other_listed(buf)
    end)
    local editor_wins = vim.tbl_filter(is_editor_window, vim.api.nvim_tabpage_list_wins(0))
    if #editor_wins > 1 and (other == nil or #vim.fn.win_findbuf(other) > 0) then
      -- Like IntelliJ: closing the last tab of a split closes the split
      vim.api.nvim_win_close(win, false)
    elseif other then
      vim.api.nvim_win_set_buf(win, other)
    else
      vim.api.nvim_win_call(win, vim.cmd.enew)
    end
  end
  local ok, err = pcall(vim.api.nvim_buf_delete, buf, {})
  if not ok then
    vim.notify(err, vim.log.levels.WARN)
  end
end

-- MoveTabRight / MoveTabDown: move the current tab into a new split
function M.move_to_new_split(vertical)
  local buf = vim.api.nvim_get_current_buf()
  local src = vim.api.nvim_get_current_win()
  local other = other_listed(buf)
  vim.cmd(vertical and "vsplit" or "split")
  if other then
    vim.api.nvim_win_set_buf(src, other)
  end
end

-- MoveEditorToOppositeTabGroup
function M.move_to_opposite_group()
  local wins = vim.tbl_filter(is_editor_window, vim.api.nvim_tabpage_list_wins(0))
  local src = vim.api.nvim_get_current_win()
  if #wins < 2 or not is_editor_window(src) then
    vim.notify("No opposite split", vim.log.levels.INFO)
    return
  end
  local idx = 1
  for i, w in ipairs(wins) do
    if w == src then
      idx = i
    end
  end
  local target = wins[idx % #wins + 1]
  local buf = vim.api.nvim_get_current_buf()
  local other = other_listed(buf)
  vim.api.nvim_win_set_buf(target, buf)
  if other then
    vim.api.nvim_win_set_buf(src, other)
  else
    vim.api.nvim_win_close(src, false)
  end
  vim.api.nvim_set_current_win(target)
end

local function has_lsp()
  return #vim.lsp.get_clients({ bufnr = 0 }) > 0
end

local function jump_to(item)
  vim.cmd("normal! m'")
  vim.cmd.edit(vim.fn.fnameescape(item.filename))
  vim.api.nvim_win_set_cursor(0, { item.lnum, math.max(item.col - 1, 0) })
  vim.cmd("normal! zz")
end

-- GotoDeclaration: jump to declaration, or show usages when already on it
function M.goto_declaration()
  if not has_lsp() then
    vim.cmd("normal! gd")
    return
  end
  local pos = vim.api.nvim_win_get_cursor(0)
  local fname = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
  vim.lsp.buf.definition({
    on_list = function(t)
      local items = t.items
      if #items == 0 then
        vim.notify("No declaration found", vim.log.levels.INFO)
        return
      end
      for _, item in ipairs(items) do
        local same_file = vim.fs.normalize(item.filename) == fname
        local end_col = item.end_col or item.col
        if same_file and item.lnum == pos[1] and pos[2] + 1 >= item.col and pos[2] + 1 <= end_col then
          require("telescope.builtin").lsp_references({ include_declaration = false })
          return
        end
      end
      if #items == 1 then
        jump_to(items[1])
      else
        vim.fn.setqflist({}, " ", t)
        require("telescope.builtin").quickfix()
      end
    end,
  })
end

-- GotoSuperMethod
function M.goto_super()
  if vim.bo.filetype == "java" then
    require("jdtls").super_implementation()
  else
    vim.lsp.buf.typehierarchy("supertypes")
  end
end

local CLASS_KINDS = { [5] = true, [10] = true, [11] = true, [23] = true } -- Class, Enum, Interface, Struct

local function goto_class_lsp_only()
  if has_lsp() then
    require("telescope.builtin").lsp_dynamic_workspace_symbols({
      symbols = { "class", "interface", "enum", "struct", "module" },
    })
  else
    require("telescope.builtin").find_files()
  end
end

-- Project classes from the file system (Java/Kotlin/Groovy file = class), tests last
local function project_classes()
  local files = vim.fn.systemlist({ "rg", "--files", "-g", "*.java", "-g", "*.kt", "-g", "*.groovy" })
  if vim.v.shell_error ~= 0 then
    return {}
  end
  local entries = {}
  for _, path in ipairs(files) do
    local dir = vim.fn.fnamemodify(path, ":h")
    table.insert(entries, {
      name = vim.fn.fnamemodify(path, ":t:r"),
      package = (dir:match("src/%w+/%w+/(.+)$") or dir):gsub("/", "."),
      filename = path,
      lnum = 1,
      col = 1,
      test = path:find("src/test/", 1, true) ~= nil,
    })
  end
  table.sort(entries, function(a, b)
    if a.test ~= b.test then
      return not a.test
    end
    return a.name < b.name
  end)
  return entries
end

local function symbol_client()
  local client = vim.lsp.get_clients({ name = "jdtls" })[1]
  if client then
    return client
  end
  for _, c in ipairs(vim.lsp.get_clients()) do
    if c:supports_method("workspace/symbol") then
      return c
    end
  end
  return nil
end

-- GotoClass: fuzzy match on the class name only. Project classes always rank above
-- library classes (JDK, Spring, ...), which come from the language server as you type.
function M.goto_class()
  local project = project_classes()
  if #project == 0 then
    goto_class_lsp_only()
    return
  end

  local channel = require("plenary.async.control").channel
  local cwd_uri = vim.uri_from_fname(vim.uv.cwd())
  local client = symbol_client()
  local pending = nil

  local function library_classes(query)
    if client == nil or client:is_stopped() then
      return {}
    end
    if pending then
      client:cancel_request(pending)
    end
    local tx, rx = channel.oneshot()
    local _, id = client:request("workspace/symbol", { query = query }, function(err, result)
      tx(err == nil and result or {})
    end)
    pending = id
    local out = {}
    local seen = {}
    for _, sym in ipairs(rx() or {}) do
      local uri = sym.location and sym.location.uri
      local key = sym.name .. " " .. (sym.containerName or "")
      if CLASS_KINDS[sym.kind] and uri and not vim.startswith(uri, cwd_uri) and not seen[key] then
        seen[key] = true
        local range = sym.location.range
        table.insert(out, {
          name = sym.name,
          package = sym.containerName or "",
          filename = vim.uri_to_fname(uri),
          lnum = range and range.start.line + 1 or 1,
          col = range and range.start.character + 1 or 1,
          library = true,
        })
      end
    end
    return out
  end

  local conf = require("telescope.config").values
  local displayer = require("telescope.pickers.entry_display").create({
    separator = "  ",
    items = { { remaining = true }, { remaining = true }, { remaining = true } },
  })

  -- Same fuzzy scoring, but every library class scores worse than any project class
  local sorter = conf.generic_sorter({})
  local base_score = sorter.scoring_function
  sorter.scoring_function = function(self, prompt, line, entry, ...)
    local score = base_score(self, prompt, line, entry, ...)
    if score < 0 then
      return score
    end
    -- fzf scores are in (0, 1], lower is better: exact name < name prefix < other fuzzy matches
    local name, query = entry.value.name:lower(), prompt:lower()
    if query ~= "" and name == query then
      score = score * 0.01
    elseif query ~= "" and vim.startswith(name, query) then
      score = score * 0.1
    end
    score = score + #name * 1e-9 -- only breaks ties: shorter names first
    if entry.value.library then
      score = score + 2
    end
    return score
  end

  require("telescope.pickers").new({}, {
    prompt_title = "Goto Class",
    finder = require("telescope.finders").new_dynamic({
      fn = function(prompt)
        local results = vim.list_extend({}, project)
        if prompt ~= "" then
          vim.list_extend(results, library_classes(prompt))
        end
        return results
      end,
      entry_maker = function(e)
        return {
          value = e,
          ordinal = e.name,
          filename = e.filename,
          lnum = e.lnum,
          col = e.col,
          display = function()
            local tag = e.library and "library" or (e.test and "test" or "")
            return displayer({ e.name, { e.package, "Comment" }, { tag, "DiagnosticHint" } })
          end,
        }
      end,
    }),
    sorter = sorter,
    previewer = conf.qflist_previewer({}),
  }):find()
end

-- The breakpoint on the cursor line, if any
local function breakpoint_here()
  local buf = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  for _, bp in ipairs(require("dap.breakpoints").get(buf)[buf] or {}) do
    if bp.line == line then
      return bp
    end
  end
  return nil
end

-- Breakpoint condition (Java expression); prefilled when editing an existing one
function M.conditional_breakpoint()
  local existing = breakpoint_here()
  vim.ui.input({ prompt = "Condition: ", default = existing and existing.condition or "" }, function(condition)
    if condition ~= nil and condition ~= "" then
      require("dap").set_breakpoint(condition)
      require("persistent-breakpoints.api").breakpoints_changed_in_current_buffer()
    end
  end)
end

-- Log point: prints the message when the line runs, without stopping. Use {expr} for values.
function M.log_point()
  local existing = breakpoint_here()
  vim.ui.input({ prompt = "Log message: ", default = existing and existing.logMessage or "" }, function(message)
    if message ~= nil and message ~= "" then
      require("dap").set_breakpoint(nil, nil, message)
      require("persistent-breakpoints.api").breakpoints_changed_in_current_buffer()
    end
  end)
end

-- Cycle the Codeium suggestion; returns true when one was shown (stops the blink key chain)
function M.cycle_ai_suggestion(delta)
  local virtual_text = package.loaded["codeium.virtual_text"]
  if virtual_text == nil or virtual_text.get_current_completion_item() == nil then
    return false
  end
  vim.schedule(function()
    virtual_text.cycle_completions(delta)
  end)
  return true
end

-- View Breakpoints: picker over all breakpoints, Enter jumps to one
function M.list_breakpoints()
  local items = {}
  for bufnr, bps in pairs(require("dap.breakpoints").get()) do
    for _, bp in ipairs(bps) do
      local text = vim.trim(vim.api.nvim_buf_get_lines(bufnr, bp.line - 1, bp.line, false)[1] or "")
      if bp.condition then
        text = text .. "  [if " .. bp.condition .. "]"
      end
      if bp.logMessage then
        text = text .. "  [log " .. bp.logMessage .. "]"
      end
      table.insert(items, {
        bufnr = bufnr,
        filename = vim.api.nvim_buf_get_name(bufnr),
        lnum = bp.line,
        col = 1,
        text = text,
      })
    end
  end
  if #items == 0 then
    vim.notify("No breakpoints", vim.log.levels.INFO)
    return
  end
  table.sort(items, function(a, b)
    if a.filename ~= b.filename then
      return a.filename < b.filename
    end
    return a.lnum < b.lnum
  end)

  local conf = require("telescope.config").values
  require("telescope.pickers").new({}, {
    prompt_title = "Breakpoints",
    finder = require("telescope.finders").new_table({
      results = items,
      entry_maker = require("telescope.make_entry").gen_from_quickfix({}),
    }),
    sorter = conf.generic_sorter({}),
    previewer = conf.qflist_previewer({}),
  }):find()
end

-- GotoRelated: class <-> test (Java/Kotlin), component siblings (TS/Angular)
function M.goto_related()
  local name = vim.fn.expand("%:t:r")
  local ext = vim.fn.expand("%:e")
  local current = vim.fn.expand("%:.")
  local globs = {}
  if ext == "java" or ext == "kt" then
    local base = name:gsub("Tests?$", ""):gsub("IT$", "")
    if base ~= name then
      globs = { "**/" .. base .. ".java", "**/" .. base .. ".kt" }
    else
      for _, suffix in ipairs({ "Test", "Tests", "IT" }) do
        table.insert(globs, "**/" .. name .. suffix .. "." .. ext)
      end
    end
  else
    local stem = name:gsub("%.spec$", ""):gsub("%.test$", "")
    globs = { "**/" .. stem .. ".*" }
  end
  local cmd = { "rg", "--files" }
  for _, g in ipairs(globs) do
    vim.list_extend(cmd, { "-g", g })
  end
  local files = vim.tbl_filter(function(f)
    return f ~= current
  end, vim.fn.systemlist(cmd))
  if #files == 0 then
    vim.notify("No related files", vim.log.levels.INFO)
  elseif #files == 1 then
    vim.cmd.edit(vim.fn.fnameescape(files[1]))
  else
    vim.ui.select(files, { prompt = "Related files" }, function(choice)
      if choice then
        vim.cmd.edit(vim.fn.fnameescape(choice))
      end
    end)
  end
end

-- OptimizeImports
function M.organize_imports()
  if vim.bo.filetype == "java" then
    require("jdtls").organize_imports()
  else
    vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" }, diagnostics = {} }, apply = true })
  end
end

function M.format()
  require("conform").format({ lsp_format = "fallback" })
end

-- Code action filtered by title, e.g. "field" for IntroduceField
function M.code_action_matching(kind, pattern)
  vim.lsp.buf.code_action({
    context = { only = { kind }, diagnostics = {} },
    filter = function(action)
      return pattern == nil or action.title:lower():find(pattern, 1, true) ~= nil
    end,
  })
end

-- CodeCleanup
function M.code_cleanup()
  M.organize_imports()
  vim.defer_fn(M.format, 200)
end

return M

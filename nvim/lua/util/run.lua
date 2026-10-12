-- Minimal IntelliJ-style run configurations: pick one, rerun the last one, stop it.
local M = {}

local last = nil
local term = nil

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function configurations()
  local cwd = vim.uv.cwd()
  local items = {}
  local function add(name, cmd)
    table.insert(items, { name = name, cmd = cmd })
  end

  if exists(cwd .. "/gradlew") then
    add("Gradle: bootRun", "./gradlew bootRun")
    add("Gradle: build", "./gradlew build")
    add("Gradle: test", "./gradlew test")
    add("Gradle: clean build", "./gradlew clean build")
  end
  if exists(cwd .. "/pom.xml") then
    local mvn = exists(cwd .. "/mvnw") and "./mvnw" or "mvn"
    add("Maven: spring-boot:run", mvn .. " spring-boot:run")
    add("Maven: test", mvn .. " test")
    add("Maven: clean install", mvn .. " clean install")
  end
  if exists(cwd .. "/package.json") then
    local ok, pkg = pcall(function()
      return vim.json.decode(table.concat(vim.fn.readfile(cwd .. "/package.json"), "\n"))
    end)
    if ok and type(pkg.scripts) == "table" then
      local names = vim.tbl_keys(pkg.scripts)
      table.sort(names)
      for _, script in ipairs(names) do
        add("npm: " .. script, "npm run " .. script)
      end
    end
  end
  if vim.bo.filetype == "java" then
    table.insert(items, { name = "JUnit: current class", fn = function() require("jdtls").test_class() end })
    table.insert(items, { name = "JUnit: nearest method", fn = function() require("jdtls").test_nearest_method() end })
  end
  table.insert(items, { name = "Custom command...", custom = true })
  return items
end

local function execute(item)
  last = item
  if item.fn then
    item.fn()
    return
  end
  if term ~= nil then
    term:shutdown()
  end
  term = require("toggleterm.terminal").Terminal:new({
    cmd = item.cmd,
    dir = vim.uv.cwd(),
    direction = "horizontal",
    close_on_exit = false,
    hidden = true,
    display_name = item.name,
  })
  term:open()
  vim.cmd("wincmd p")
end

-- RedesignedRunConfigurationSelector
function M.select()
  vim.ui.select(configurations(), {
    prompt = "Run configuration",
    format_item = function(item)
      return item.name
    end,
  }, function(item)
    if item == nil then
      return
    end
    if item.custom then
      vim.ui.input({ prompt = "Command: " }, function(cmd)
        if cmd and cmd ~= "" then
          execute({ name = cmd, cmd = cmd })
        end
      end)
    else
      execute(item)
    end
  end)
end

-- Run: rerun the last configuration (asks the first time)
function M.run()
  if last then
    execute(last)
  else
    M.select()
  end
end

-- Stop: Ctrl-C the running configuration, and stop any debug session
function M.stop()
  if term ~= nil and term.job_id then
    pcall(vim.fn.chansend, term.job_id, "\x03")
  end
  local ok, dap = pcall(require, "dap")
  if ok and dap.session() then
    dap.terminate()
  end
end

return M

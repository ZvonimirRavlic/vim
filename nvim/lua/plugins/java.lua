local function start_jdtls()
  local jdtls = require("jdtls")
  local mason = vim.fn.stdpath("data") .. "/mason"
  local root = vim.fs.root(0, {
    { "gradlew", "mvnw", "settings.gradle", "settings.gradle.kts" },
    ".git",
    { "pom.xml", "build.gradle", "build.gradle.kts" },
  })
  if root == nil then
    return
  end
  local workspace = vim.fn.stdpath("cache") .. "/jdtls/" .. root:gsub("[/\\:]", "_")

  local cmd = { mason .. "/bin/jdtls" }
  local lombok = mason .. "/packages/jdtls/lombok.jar"
  if vim.uv.fs_stat(lombok) then
    table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok)
  end
  vim.list_extend(cmd, { "-data", workspace })

  local bundles = vim.fn.glob(mason .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar", true, true)
  for _, jar in ipairs(vim.fn.glob(mason .. "/packages/java-test/extension/server/*.jar", true, true)) do
    local name = vim.fn.fnamemodify(jar, ":t")
    if name ~= "com.microsoft.java.test.runner-jar-with-dependencies.jar" and name ~= "jacocoagent.jar" then
      table.insert(bundles, jar)
    end
  end

  jdtls.start_or_attach({
    cmd = cmd,
    root_dir = root,
    capabilities = require("blink.cmp").get_lsp_capabilities(),
    settings = {
      java = {
        signatureHelp = { enabled = true },
        contentProvider = { preferred = "fernflower" },
        configuration = { updateBuildConfiguration = "interactive" },
        sources = { organizeImports = { starThreshold = 99, staticStarThreshold = 99 } },
        completion = {
          favoriteStaticMembers = {
            "org.junit.jupiter.api.Assertions.*",
            "org.assertj.core.api.Assertions.*",
            "org.mockito.Mockito.*",
            "org.mockito.ArgumentMatchers.*",
          },
        },
      },
    },
    init_options = { bundles = bundles, extendedClientCapabilities = jdtls.extendedClientCapabilities },
    on_attach = function()
      pcall(jdtls.setup_dap, { hotcodereplace = "auto" })
      pcall(function()
        require("jdtls.dap").setup_dap_main_class_configs()
      end)
    end,
  })
end

return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    dependencies = { "mfussenegger/nvim-dap", "saghen/blink.cmp" },
    config = function()
      vim.api.nvim_create_autocmd("FileType", { pattern = "java", callback = start_jdtls })
      if vim.bo.filetype == "java" then
        start_jdtls()
      end
    end,
  },
}

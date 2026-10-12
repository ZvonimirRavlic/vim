return {
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" }, opts = {} },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui"] = function() dapui.close() end
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapLogPoint", { text = "◉", texthl = "DiagnosticInfo" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual" })
    end,
  },

  -- Breakpoints survive restarts (saved per project folder, reloaded when a file opens)
  {
    "Weissle/persistent-breakpoints.nvim",
    lazy = false,
    dependencies = { "mfussenegger/nvim-dap" },
    opts = { load_breakpoints_event = { "BufReadPost" } },
  },
}

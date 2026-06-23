return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  event = "VeryLazy",
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    local ok, defaults = pcall(require, "plugins.lsp.defaults")
    if ok and defaults.ensure_installed then
      require("mason-tool-installer").setup({
        ensure_installed = defaults.ensure_installed,
        run_on_start = true,
        start_delay = 3000,
      })
    end
  end,
}

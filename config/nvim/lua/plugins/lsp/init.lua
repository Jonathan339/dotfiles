local M = {
  "williamboman/mason.nvim",
  event = "VeryLazy",
  cmd = { "Mason", "MasonInstall", "MasonUpdate" },
  --lazy = false,
  dependencies = {
    { "neovim/nvim-lspconfig", event = "BufReadPre" },
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "williamboman/mason-lspconfig.nvim",
    "j-hui/fidget.nvim",
    {
      "folke/neodev.nvim",
      config = function()
        require("neodev").setup({
          library = {
            plugins = { "nvim-dap-ui" },
            types = true,
          },
        })
      end,
    },
  },

  config = function()
    local ensure_installed = require("plugins.lsp.defaults").ensure_installed
    local fidget = require("fidget")
    local mason = require("mason")
    local mason_installer = require("mason-tool-installer")
    local mason_lspconfig = require("mason-lspconfig")

    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_installer.setup({
      ensure_installed = ensure_installed,
      -- auto_update = true, -- No actualizar automáticamente
      -- run_on_start = true, -- Instalar herramientas al iniciar Neovim
    })

    vim.api.nvim_create_autocmd('User', {
      pattern = 'MasonToolsUpdateCompleted',
      callback = function()
        vim.schedule(function()
          vim.notify(
            ' Mason-tool-installer has finished updating packages',
            'info',
            { title = 'Mason Tool Installer' }
          )
        end)
      end,
    })

    mason_lspconfig.setup({
      handlers = require("plugins.lsp.handlers"),
    })

    fidget.setup({
      text = {
        done = "✓", -- Ícono para indicar que el progreso está completo
      },
      window = {
        relative = "win", -- La ventana de fidget se posiciona relativa a la ventana de Neovim
      },
      -- Si tienes configuraciones personalizadas de notificaciones, las puedes agregar aquí.
    })
  end,
}

return M

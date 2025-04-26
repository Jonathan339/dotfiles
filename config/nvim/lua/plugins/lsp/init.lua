local M = {
  'williamboman/mason.nvim',
  event = 'VeryLazy',
  cmd = { 'Mason', 'MasonInstall', 'MasonUpdate' },
  dependencies = {
    { 'neovim/nvim-lspconfig', event = 'BufReadPre' },
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'williamboman/mason-lspconfig.nvim',
    'j-hui/fidget.nvim',
    {
      'folke/neodev.nvim',
      config = function()
        require('neodev').setup({
          library = {
            plugins = { 'nvim-dap-ui' },
            types = true,
          },
        })
      end,
    },
  },
}

M.config = function()
  local ensure_installed = require('plugins.lsp.defaults').ensure_installed
  M.mason()
  M.mason_installer(ensure_installed)
  M.mason_lspconfig()
  M.fidget()
end

M.mason = function()
  require('mason').setup({
    ui = {
      icons = {
        package_installed = '✓',
        package_pending = '➜',
        package_uninstalled = '✗',
      },
    },
  })
end

M.mason_installer = function(ensure_installed)
  require('mason-tool-installer').setup({
    ensure_installed = ensure_installed,
    -- auto_update = true,
    -- run_on_start = true,
  })

  vim.api.nvim_create_autocmd('User', {
    pattern = 'MasonToolsUpdateCompleted',
    callback = function()
      vim.schedule(function()
        vim.notify(' Mason-tool-installer has finished updating packages', 'info', { title = 'Mason Tool Installer' })
      end)
    end,
  })
end

M.mason_lspconfig = function()
  require('mason-lspconfig').setup({
    handlers = require('plugins.lsp.handlers'),
  })
end

M.fidget = function()
  require('fidget').setup({
    text = {
      done = '✓',
    },
    window = {
      relative = 'win',
    },
  })
end

return M

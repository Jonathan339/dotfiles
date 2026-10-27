-- lua/plugins/lsp/init.lua
-- LSP independiente de Mason: se activa al abrir un archivo, no cuando Mason
-- termina de cargar (antes, si Mason fallaba, no había LSP).
return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    -- cmp-nvim-lsp se carga en InsertEnter, pero acá lo requerimos al calcular
    -- capabilities. Sin esta dependencia el require falla y el LSP anuncia
    -- capabilities sin snippetSupport/labelDetails.
    'hrsh7th/cmp-nvim-lsp',
    {
      'j-hui/fidget.nvim',
      tag = 'legacy',
      opts = { text = { done = '✓' }, window = { relative = 'win' } },
    },
  },
  config = function()
    vim.diagnostic.config({
      virtual_text = { prefix = '●', spacing = 2, source = 'always' },
      signs = true,
      underline = true,
      update_in_insert = true,
      severity_sort = true,
      float = { border = 'rounded', source = 'always' },
    })
    local signs = {
      Error = { text = '✗', texthl = 'DiagnosticSignError' },
      Warn = { text = '⚠', texthl = 'DiagnosticSignWarn' },
      Info = { text = 'ℹ', texthl = 'DiagnosticSignInfo' },
      Hint = { text = '💡', texthl = 'DiagnosticSignHint' },
    }
    for type, sign in pairs(signs) do
      vim.fn.sign_define('DiagnosticSign' .. type, sign)
    end

    -- Colores custom para los signs de diagnostico
    vim.api.nvim_set_hl(0, { group = 'DiagnosticSignError', fg = '#ff5555' })
    vim.api.nvim_set_hl(0, { group = 'DiagnosticSignWarn', fg = '#ffaa00' })
    vim.api.nvim_set_hl(0, { group = 'DiagnosticSignInfo', fg = '#44aaff' })
    vim.api.nvim_set_hl(0, { group = 'DiagnosticSignHint', fg = '#aa44ff' })

    local handlers = require('plugins.lsp.handlers')
    local servers = {}
    for _, name in ipairs({
      'bashls',
      'pyright',
      'ruff',
      'html',
      'cssls',
      'clangd',
      'vtsls',
      'eslint',
      'lua_ls',
      'typos_lsp',
      'jsonls',
      'yamlls',
      'taplo',
      'tailwindcss',
      'marksman',
      'emmet_ls',
    }) do
      if handlers[name] then
        handlers[name]()
        table.insert(servers, name)
      end
    end

    vim.lsp.enable(servers)
  end,
}

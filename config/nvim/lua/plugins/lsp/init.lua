return {
  'williamboman/mason.nvim',
  event = 'VeryLazy',
  cmd = { 'Mason', 'MasonInstall', 'MasonUpdate' },
  dependencies = {
    'neovim/nvim-lspconfig',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    { 'j-hui/fidget.nvim', tag = 'legacy', opts = { text = { done = '✓' }, window = { relative = 'win' } } },

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
    for type, icon in pairs({ Error = ' ', Warn = ' ', Hint = ' ', Info = ' ' }) do
      vim.fn.sign_define('DiagnosticSign' .. type, { text = icon, texthl = 'DiagnosticSign' .. type })
    end

    require('mason').setup({
      ui = {
        border = 'rounded',
        icons = { package_installed = '✓', package_pending = '➜', package_uninstalled = '✗' },
      },
    })

    require('mason-tool-installer').setup({
      ensure_installed = {
        'bash-language-server',
        'clangd',
        'clang-format',
        'css-lsp',
        'dockerfile-language-server',
        'dprint',
        'emmet-language-server',
        'eslint-lsp',
        'eslint_d',
        'html-lsp',
        'json-lsp',
        'lua-language-server',
        'marksman',
        'prettier',
        'pyright',
        'black',
        'isort',
        'ruff',
        'shfmt',
        'shellcheck',
        'sqls',
        'stylua',
        'taplo',
        'vim-language-server',
        'vtsls',
        'yaml-language-server',
      },
    })

    local defaults = require('plugins.lsp.defaults')

    local servers = {}

    for _, name in ipairs({ 'bashls', 'pyright', 'html', 'cssls', 'clangd' }) do
      vim.lsp.config(name, {
        capabilities = defaults.capabilities,
        on_attach = defaults.on_attach,
        on_init = defaults.on_init,
      })
      table.insert(servers, name)
    end

    local handlers = require('plugins.lsp.handlers')
    for _, name in ipairs({ 'vtsls', 'eslint', 'lua_ls', 'dprint', 'efm', 'typos_lsp', 'jsonls' }) do
      if handlers[name] then
        handlers[name]()
        table.insert(servers, name)
      end
    end

    vim.lsp.enable(servers)
  end,
}

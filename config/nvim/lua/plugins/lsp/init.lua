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
        'emmet-language-server',
        'tailwindcss-language-server',
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
        'shfmt',
        'shellcheck',
        'stylua',
        'taplo',
        'gofumpt',
        'goimports-reviser',
        'vtsls',
        'yaml-language-server',
        'typos-lsp',
        'efm-langserver',
      },
    })

    local has_lsp_config = pcall(function() return vim.lsp.config end)
    local servers = {}

    local handlers = require('plugins.lsp.handlers')
    for _, name in ipairs({ 'bashls', 'pyright', 'html', 'cssls', 'clangd', 'vtsls', 'eslint', 'lua_ls', 'efm', 'typos_lsp', 'jsonls', 'tailwindcss', 'marksman', 'emmet_ls' }) do
      if handlers[name] then
        handlers[name]()
        if has_lsp_config then
          table.insert(servers, name)
        end
      end
    end

    if has_lsp_config then
      vim.lsp.enable(servers)
    end
  end,
}

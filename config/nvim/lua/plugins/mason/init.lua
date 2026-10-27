-- lua/plugins/mason/init.lua
-- Mason solo instala/actualiza herramientas. El LSP se configura aparte en
-- plugins/lsp/init.lua para que no dependa de que Mason cargue.
return {
  'williamboman/mason.nvim',
  event = 'VeryLazy',
  cmd = { 'Mason', 'MasonInstall', 'MasonUpdate', 'MasonUninstall' },
  dependencies = { 'WhoIsSethDaniel/mason-tool-installer.nvim' },
  config = function()
    require('mason').setup({
      ui = {
        border = 'rounded',
        icons = { package_installed = '✓', package_pending = '➜', package_uninstalled = '✗' },
      },
    })

    -- Herramientas que usa esta config (conform, nvim-lint y LSP).
    local tools = {
      -- LSP
      'bash-language-server',
      'css-lsp',
      'emmet-language-server',
      'eslint-lsp',
      'html-lsp',
      'json-lsp',
      'lua-language-server',
      'marksman',
      'pyright',
      'ruff',
      'tailwindcss-language-server',
      'typos-lsp',
      'vtsls',
      'yaml-language-server',
      -- Formatters / linters
      'clang-format',
      'eslint_d',
      'markdownlint-cli2',
      'prettier',
      'shfmt',
      'stylua',
      'taplo',
      'yamllint',
    }

    -- Herramientas que Mason compila/instala con runtimes que hoy no están:
    -- no encolarlas para que no fallen en cada arranque.
    if vim.fn.executable('go') == 1 then
      vim.list_extend(tools, { 'gofumpt', 'goimports-reviser', 'staticcheck' })
    end
    if vim.fn.executable('cargo') == 1 then
      table.insert(tools, 'alejandra')
    end

    require('mason-tool-installer').setup({ ensure_installed = tools })
  end,
}

-- lua/plugins/lsp/init.lua
local M = {
  'williamboman/mason.nvim',
  event = 'VeryLazy',
  cmd = { 'Mason', 'MasonInstall', 'MasonUpdate' },
  dependencies = {
    { 'neovim/nvim-lspconfig', lazy = false },
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    { 'j-hui/fidget.nvim', tag = 'legacy', opts = { text = { done = '✓' }, window = { relative = 'win' } } },
    {
      'folke/neodev.nvim',
      event = 'VeryLazy',
      opts = {
        library = { plugins = true, types = true },
        override = function(_, _) end,
      },
    },
  },
}

M.config = function()
  local defaults = require('plugins.lsp.defaults')

  do
    local ok_cfg, cfg = pcall(require, 'plugins.lsp.diagnostics.config')
    if ok_cfg and cfg then
      vim.diagnostic.config(cfg)
      local signs = { Error = ' ', Warn = ' ', Hint = ' ', Info = ' ' }
      for t, icon in pairs(signs) do
        local hl = 'DiagnosticSign' .. t
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
      end
    end
  end

  require('mason').setup({
    ui = {
      border = 'rounded',
      icons = { package_installed = '✓', package_pending = '➜', package_uninstalled = '✗' },
    },
  })

  local ok_mlsp, mlsp = pcall(require, 'mason-lspconfig')
  if not ok_mlsp then
    return
  end

  mlsp.setup({
    ensure_installed = defaults.lsp_servers,
    automatic_installation = true,
  })

  local ok_mti, mti = pcall(require, 'mason-tool-installer')
  if ok_mti then
    mti.setup({
      ensure_installed = defaults.ensure_installed,
      auto_update = false,
      run_on_start = true,
      start_delay = 3000,
      debounce_hours = 12,
    })
  end

  local capabilities = defaults.capabilities

  local function on_attach(_, bufnr)
    local map = function(m, lhs, rhs, desc)
      vim.keymap.set(m, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end
    map('n', 'gd', vim.lsp.buf.definition, 'Goto Definition')
    map('n', 'gr', vim.lsp.buf.references, 'References')
    map('n', 'gi', vim.lsp.buf.implementation, 'Implementation')
    map('n', 'K', vim.lsp.buf.hover, 'Hover')
    map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename')
    map('n', '<leader>ca', vim.lsp.buf.code_action, 'Code Action')
    map('n', '[d', vim.diagnostic.goto_prev, 'Prev Diagnostic')
    map('n', ']d', vim.diagnostic.goto_next, 'Next Diagnostic')
    map('n', '<leader>f', function()
      vim.lsp.buf.format({ async = true })
    end, 'Format')

    defaults.on_attach(_, bufnr)
  end

  local server_opts = {
    lua_ls = {
      settings = {
        Lua = {
          completion = { callSnippet = 'Replace' },
          diagnostics = { globals = { 'vim' } },
          workspace = { checkThirdParty = false },
        },
      },
    },
    ts_ls = {},
    pyright = {},
    bashls = {},
    html = {},
    cssls = {},
    jsonls = {},
    yamlls = {},
    tailwindcss = {},
    dockerls = {},
    marksman = {},
  }

  local function with_common(o)
    o = o or {}
    o.capabilities = capabilities
    o.on_attach = on_attach
    o.on_init = defaults.on_init
    return o
  end

  local lsp = require('lspconfig')

  if type(mlsp.setup_handlers) == 'function' then
    mlsp.setup_handlers({
      function(server_name)
        local opts = with_common(server_opts[server_name] or {})
        if server_name == 'lua_ls' then
          pcall(require, 'neodev')
        end
        lsp[server_name].setup(opts)
      end,
    })
  else
    mlsp.setup({
      handlers = {
        function(server_name)
          local opts = with_common(server_opts[server_name] or {})
          if server_name == 'lua_ls' then
            pcall(require, 'neodev')
          end
          lsp[server_name].setup(opts)
        end,
      },
    })
  end
end

return M

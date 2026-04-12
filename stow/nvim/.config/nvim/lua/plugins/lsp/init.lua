-- lua/plugins/lsp/init.lua
local M = {
  'williamboman/mason.nvim',
  event = 'VeryLazy',
  cmd = { 'Mason', 'MasonInstall', 'MasonUpdate' },
  dependencies = {
    -- Evitar carreras con auto_ensure (tu comentario es válido)
    { 'neovim/nvim-lspconfig', lazy = false },

    'williamboman/mason-lspconfig.nvim',

    -- UI de progreso (API legacy estable)
    { 'j-hui/fidget.nvim', tag = 'legacy', opts = { text = { done = '✓' }, window = { relative = 'win' } } },

    -- Mejor experiencia para lua_ls (cargar antes de setup de lua_ls)
    {
      'folke/neodev.nvim',
      -- si usás lazy.nvim podés cargarlo muy temprano
      event = 'VeryLazy',
      opts = {
        -- evita advertencias por “third party”
        library = { plugins = true, types = true },
        -- desactiva chequeos externos ruidosos
        override = function(_, _)
          -- podés dejar vacío; el punto es que se inicialice
        end,
      },
    },
  },
}

M.config = function()
  -- 1) Diagnósticos unificados (si tenés el módulo)
  do
    local ok_cfg, cfg = pcall(require, 'plugins.lsp.diagnostics.config')
    if ok_cfg and cfg then
      vim.diagnostic.config(cfg)
      -- signos por si tu módulo no los define
      local signs = { Error = ' ', Warn = ' ', Hint = ' ', Info = ' ' }
      for t, icon in pairs(signs) do
        local hl = 'DiagnosticSign' .. t
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
      end
    end
  end

  -- 2) Mason UI
  require('mason').setup({
    ui = {
      border = 'rounded',
      icons = { package_installed = '✓', package_pending = '➜', package_uninstalled = '✗' },
    },
  })

  -- 3) mason-lspconfig + lspconfig
  local ok_mlsp, mlsp = pcall(require, 'mason-lspconfig')
  if not ok_mlsp then
    return
  end

  -- capabilities (si está cmp-nvim-lsp)
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  do
    local ok_cmp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
    if ok_cmp then
      capabilities = cmp_lsp.default_capabilities(capabilities)
    end
  end

  -- on_attach básico (usa tu handlers.lua si lo preferís)
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
  end

  -- 4) Lista de servidores y ajustes por servidor
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
  }

  -- Hook común para todos
  local function with_common(o)
    o = o or {}
    o.capabilities = capabilities
    o.on_attach = on_attach
    return o
  end

  local lsp = require('lspconfig')

  -- 5) Compat: handlers API vieja vs nueva
  if type(mlsp.setup_handlers) == 'function' then
    -- API nueva: callback por servidor
    mlsp.setup({})
    mlsp.setup_handlers({
      function(server_name)
        local opts = with_common(server_opts[server_name] or {})
        -- neodev debe estar antes de lua_ls
        if server_name == 'lua_ls' then
          pcall(require, 'neodev') -- ya se cargó por dependencia, por las dudas
        end
        lsp[server_name].setup(opts)
      end,
    })
  else
    -- API vieja: pasar handlers en setup()
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

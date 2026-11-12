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
  },
  config = function()
    require('plugins.lsp.keymaps').setup()

    -- nvim-highlight-colors ya pinta los colores del buffer; desactivar el
    -- document color del LSP evita resaltados duplicados (igual que craftzdog).
    if vim.lsp.document_color then
      vim.lsp.document_color.enable(false)
    end

    local icons = require('utils.icons').get('diagnostics')
    vim.diagnostic.config({
      virtual_text = { prefix = icons.Circle, spacing = 3, source = 'always' },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = icons.Error,
          [vim.diagnostic.severity.WARN] = icons.Warning,
          [vim.diagnostic.severity.INFO] = icons.Information,
          [vim.diagnostic.severity.HINT] = icons.Hint,
        },
      },
      underline = true,
      -- craftzdog lo deja en false: actualizar diagnósticos en cada tecla
      -- cuesta caro en archivos grandes y mete ruido visual.
      update_in_insert = false,
      severity_sort = true,
      float = { border = 'rounded', source = 'always' },
    })
    local handlers = require('plugins.lsp.handlers')
    local servers = {}
    -- Oxlint reemplaza a ESLint cuando el binario está instalado; si todavía
    -- no está, ESLint queda como fallback.
    local has_oxlint = vim.fn.executable('oxlint') == 1

    -- ~/.cargo/bin/rust-analyzer es un shim de rustup: comprobar que el
    -- componente esté realmente instalado en alguna toolchain.
    local function has_rust_analyzer()
      if vim.fn.executable('rust-analyzer') ~= 1 then
        return false
      end
      local resolved = vim.fn.resolve(vim.fn.exepath('rust-analyzer'))
      if vim.fn.fnamemodify(resolved, ':t') ~= 'rustup' then
        return true
      end
      local rustup_home = vim.env.RUSTUP_HOME or vim.fn.expand('~/.rustup')
      return #vim.fn.glob(rustup_home .. '/toolchains/*/bin/rust-analyzer', false, true) > 0
    end

    local rust_analyzer_ok = has_rust_analyzer()
    for _, name in ipairs({
      'bashls',
      'pyright',
      'ruff',
      'html',
      'cssls',
      'clangd',
      'vtsls',
      'eslint',
      'oxlint',
      'rust_analyzer',
      'lua_ls',
      'typos_lsp',
      'jsonls',
      'yamlls',
      'taplo',
      'tailwindcss',
      'marksman',
      'emmet_ls',
    }) do
      local enabled = (name ~= 'oxlint' or has_oxlint) and (name ~= 'rust_analyzer' or rust_analyzer_ok)
      if enabled and handlers[name] then
        handlers[name]()
        table.insert(servers, name)
      end
    end

    vim.lsp.enable(servers)
  end,
}

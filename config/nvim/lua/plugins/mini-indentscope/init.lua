return {
  'echasnovski/mini.indentscope',
  version = false,
  event = { 'BufReadPre', 'BufNewFile' },

  -- opcional, pero lo dejamos para asegurar carga perezosa
  lazy = true,

  opts = {
    symbol = '│',
    options = { try_as_border = true },
    -- draw se completa en config para añadir animación = none
  },

  init = function()
    -- Desactivar en ciertos tipos de buffer/filetype
    vim.api.nvim_create_autocmd('FileType', {
      pattern = {
        'help',
        'alpha',
        'dashboard',
        'neo-tree',
        'trouble',
        'Trouble',
        'lazy',
        'mason',
        'notify',
        'toggleterm',
        'lazyterm',
        'oil',
        'TelescopePrompt',
        'checkhealth',
        'noice',
        'spectre_panel',
      },
      callback = function()
        vim.b.miniindentscope_disable = true
      end,
    })

    -- Desactivar en markdown renderizado u otros modos especiales
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'markdown', 'quarto' },
      callback = function()
        -- si usás render-markdown.nvim o similares, mejor apagar scope
        vim.b.miniindentscope_disable = true
      end,
    })

    -- Desactivar para archivos grandes (lo marca tu autocmd)
    vim.api.nvim_create_autocmd('BufReadPost', {
      callback = function()
        if vim.b.large_file or vim.bo.buftype == 'terminal' then
          vim.b.miniindentscope_disable = true
        end
      end,
    })
  end,

  config = function(_, opts)
    local mini = require('mini.indentscope')

    -- Sin animación y sin retraso (evita flicker)
    opts.draw = vim.tbl_deep_extend('force', {
      delay = 0,
      animation = mini.gen_animation.none(),
    }, opts.draw or {})

    mini.setup(opts)
  end,
}

return {
  'nvim-cmp',
  dependencies = {
    {
      'Exafunction/codeium.nvim',
      dependencies = {
        'nvim-lua/plenary.nvim',
        'hrsh7th/nvim-cmp',
      },
      cmd = 'Codeium',
      build = ':Codeium Auth',
      opts = {},
    },
  },
  opts = function(_, opts)
    -- Inicializa opts.sources si no está inicializado
    opts.sources = opts.sources or {}
    -- Inserta el nuevo origen en opts.sources
    table.insert(opts.sources, 1, {
      name = 'codeium',
      group_index = 1,
      priority = 100,
    })
  end,
}

return {
  'hrsh7th/nvim-cmp',
  dependencies = {
    {
      'Exafunction/codeium.nvim',
      dependencies = { 'nvim-lua/plenary.nvim' },
      cmd = 'Codeium',
      build = ':Codeium Auth',
      opts = {}, -- dejá vacío o poné tus prefs
      config = function(_, opts)
        require('codeium').setup(opts)
      end,
    },
  },
  opts = function(_, opts)
    opts.sources = opts.sources or {}
    -- Insertar Codeium al principio del grupo principal
    table.insert(opts.sources, 1, {
      name = 'codeium',
      group_index = 1,
      priority = 100,
      max_item_count = 5,
    })
  end,
}

return {
  'windwp/nvim-ts-autotag',
  -- El plugin elige solo cuándo cargarse; BufReadPre/BufNewFile es lo recomendado
  -- por upstream y evita mantener una lista de filetypes desactualizada.
  event = { 'BufReadPre', 'BufNewFile' },

  dependencies = { 'nvim-treesitter/nvim-treesitter' },

  opts = {
    opts = {
      enable_close = true,
      enable_rename = true,
      enable_close_on_slash = true,
    },
  },
}

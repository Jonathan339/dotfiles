return {
  'windwp/nvim-ts-autotag',

  ft = {
    'html', 'xml', 'javascript', 'typescript',
    'jsx', 'tsx', 'javascriptreact', 'typescriptreact',
    'vue', 'svelte', 'astro',
  },

  dependencies = { 'nvim-treesitter/nvim-treesitter' },

  opts = {
    enable_close = true,
    enable_rename = true,
    enable_close_on_slash = true,

    per_filetype = {
      html = { enable_close = true, enable_rename = true },
      xml = { enable_close = true },
      tsx = { enable_close = true, enable_rename = true, enable_close_on_slash = true },
      jsx = { enable_close = true, enable_rename = true, enable_close_on_slash = true },
    },
  },
}

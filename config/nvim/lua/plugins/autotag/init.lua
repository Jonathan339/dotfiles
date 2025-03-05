return {
  -- Automatically add closing tags for HTML and JSX
  {
    'windwp/nvim-ts-autotag',
    event = { 'BufReadPost', 'BufWritePost', 'BufNewFile' },
    opts = {
      filetypes = {
        'html',
        'templ',
        'javascript',
        'typescript',
        'javascriptreact',
        'typescriptreact',
        'svelte',
        'vue',
        'tsx',
        'jsx',
        'rescript',
        'xml',
        'php',
        'markdown',
        'astro',
        'glimmer',
        'handlebars',
        'hbs',
      },
    },
    config = function(_, opts)
      require('nvim-ts-autotag').setup(opts)
    end,
  },

  -- Auto pairs
  {
    'echasnovski/mini.pairs',
    event = 'VeryLazy',
    opts = {},
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {}, -- this is equivalent to setup({}) function
  },
}

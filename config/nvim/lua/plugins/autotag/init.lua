local M = {
  'windwp/nvim-ts-autotag',
  event = { 'BufWritePost', 'BufNewFile' },
}

M.config = function()
  require('nvim-ts-autotag').setup({
    enable_close = true,          -- Auto close tags
    enable_rename = true,         -- Auto rename pairs of tags
    enable_close_on_slash = true, -- Auto close on trailing
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
    per_filetype = {
      ['html'] = {
        enable_close = true,
      },
    },
  })
end
return M

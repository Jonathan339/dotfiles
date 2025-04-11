return {
  'lukas-reineke/indent-blankline.nvim',
  event = { 'User FilePost' },
  main = 'ibl',
  opts = function()
    return {
      indent = {
        char = '▏',
        highlight = { 'IBLIndent' },
      },
      scope = {
        injected_languages = false,
        highlight = { 'IBLScope' },
        include = {
          node_type = {
            ['*'] = { -- Patrón que coincide con cualquier tipo de nodo
              '^argument',
              '^expression',
              '^for',
              '^if',
              '^import',
              '^export',
              '^type',
              'arguments',
              'block',
              'bracket',
              'declaration',
              'field',
              'func_literal',
              'function',
              'import_spec_list',
              'list',
              'return_statement',
              'short_var_declaration',
              'statement',
              'switch_body',
              'try',
              'object',
            },
          },
        },
      },
      exclude = {
        filetypes = { 'dashboard' },
      },
    }
  end,
}

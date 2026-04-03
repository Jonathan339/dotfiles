local M = {
  'lukas-reineke/indent-blankline.nvim',
  -- desde ibl v3, el módulo principal es "ibl"
  event = { 'BufReadPost', 'BufNewFile' },
}

M.config = function()
  -- highlights amigables con cualquier tema (solo si no existen)
  vim.api.nvim_set_hl(0, 'IBLIndent', { link = 'LineNr', default = true })
  vim.api.nvim_set_hl(0, 'IBLScope', { link = 'Function', default = true })

  -- desactivar en archivos muy grandes (>1MB) para evitar lag
  vim.api.nvim_create_autocmd('BufReadPost', {
    callback = function(args)
      local ok, stat = pcall(vim.loop.fs_stat, args.file)
      if ok and stat and stat.size > 1024 * 1024 then
        -- ibl permite deshabilitar por buffer:
        local ok_ibl, ibl = pcall(require, 'ibl')
        if ok_ibl then
          ibl.setup_buffer(0, { enabled = false })
        end
      end
    end,
  })

  -- scope solo si hay Treesitter
  local has_ts = pcall(require, 'nvim-treesitter') or pcall(require, 'nvim-treesitter.configs')

  require('ibl').setup({
    indent = {
      char = '▏',
      highlight = { 'IBLIndent' },
    },
    whitespace = {
      remove_blankline_trail = true,
    },
    scope = {
      enabled = has_ts, -- evita calcular scope sin TS
      injected_languages = false,
      highlight = { 'IBLScope' },
      -- tu lista custom de nodos puede quedarse; la dejo compacta
      include = {
        node_type = {
          ['*'] = {
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
      filetypes = {
        'help',
        'lazy',
        'mason',
        'oil',
        'TelescopePrompt',
        'alpha',
        'dashboard',
        'gitcommit',
        'markdown',
        'text',
        'Trouble',
      },
      buftypes = { 'nofile', 'terminal', 'prompt' },
    },
  })
end

return M

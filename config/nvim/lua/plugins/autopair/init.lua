local M = {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  dependencies = {
    'hrsh7th/nvim-cmp',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = function()
    return {
      check_ts = true, -- usa Treesitter para decidir
      enable_check_bracket_line = true,
      disable_filetype = { 'TelescopePrompt', 'vim' },
      ignored_next_char = '[%w%.%$]', -- no cerrar si sigue una palabra/punto/$
      fast_wrap = {
        map = '<M-e>',
        chars = { '{', '[', '(', '"', "'", '<' },
        pattern = [=[[%'%"%>%]%)%}%,%s]]=],
        end_key = 'e',
        keys = 'qwertyuiopasdfghjklzxcvbnm',
        check_comma = true,
        highlight = 'Search',
        highlight_grey = 'Comment',
      },
      ts_config = {
        lua = { 'string' }, -- no pares dentro de strings
        javascript = { 'template_string', 'string' },
        typescript = { 'template_string', 'string' },
        javascriptreact = { 'template_string', 'string' },
        typescriptreact = { 'template_string', 'string' },
      },
    }
  end,
}

M.config = function(_, opts)
  local npairs = require('nvim-autopairs')
  npairs.setup(opts)

  -- Integración con nvim-cmp: añade ( ... ) al confirmar funciones, etc.
  local ok_cmp, cmp = pcall(require, 'cmp')
  if ok_cmp then
    local cmp_autopairs = require('nvim-autopairs.completion.cmp')
    cmp.event:on(
      'confirm_done',
      cmp_autopairs.on_confirm_done({
        map_char = { tex = '' }, -- no insertar paréntesis en TeX
      })
    )
  end

  ---------------------------------------------------------------------------
  -- Reglas extra: espacios inteligentes entre () [] {} y template strings
  ---------------------------------------------------------------------------
  local Rule = require('nvim-autopairs.rule')

  -- Añade espacio dentro de pares si ya existen: (|) -> ( | )
  npairs.add_rules({
    Rule(' ', ' ')
      :with_pair(function(opts)
        local pair = opts.line:sub(opts.col - 1, opts.col)
        return pair == '()' or pair == '[]' or pair == '{}'
      end)
      :with_move(function(opts)
        return opts.prev_char:match('.%s') ~= nil
      end)
      :use_key(' '),

    Rule('( ', ' )')
      :with_pair(false)
      :with_move(function(opts)
        return opts.prev_char:match('%(%s') ~= nil
      end)
      :use_key(')'),

    Rule('{ ', ' }')
      :with_pair(false)
      :with_move(function(opts)
        return opts.prev_char:match('%{%s') ~= nil
      end)
      :use_key('}'),

    Rule('[ ', ' ]')
      :with_pair(false)
      :with_move(function(opts)
        return opts.prev_char:match('%[%s') ~= nil
      end)
      :use_key(']'),
  })

  -- Backticks en ecosistema JS/TS/React/Svelte (si no estás en string TS)
  npairs.add_rules({
    Rule('`', '`', { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'svelte' }):with_pair(function(opts)
      -- si ya hay un backtick justo antes, no dupliques
      return opts.line:sub(opts.col, opts.col) ~= '`'
    end),
  })
end

return M

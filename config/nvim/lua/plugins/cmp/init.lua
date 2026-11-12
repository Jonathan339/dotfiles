-- lua/plugins/cmp/init.lua

return {
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',

  dependencies = {
    -- Fuentes de autocompletado
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/cmp-nvim-lua',

    -- Snippets
    'saadparwaiz1/cmp_luasnip',

    -- Iconos y colores
    'onsails/lspkind.nvim',
    'brenoprata10/nvim-highlight-colors',
  },

  opts = function()
    local cmp = require('cmp')
    local luasnip = require('luasnip')

    -- Desactivar autocompletado en comentarios
    local ok_ctx, context = pcall(require, 'cmp.config.context')

    local function enabled()
      if vim.bo.buftype == 'prompt' then
        return false
      end

      if ok_ctx then
        if context.in_treesitter_capture('comment') or context.in_syntax_group('Comment') then
          return false
        end
      end

      return true
    end

    -- Formateadores opcionales
    local lspkind_ok, lspkind = pcall(require, 'lspkind')
    local nhc_ok, nhc = pcall(require, 'nvim-highlight-colors')

    local function formatter(entry, vim_item)
      -- Resaltar colores CSS y otros literales
      if nhc_ok then
        local colored = nhc.format(entry, {
          kind = vim_item.kind,
        })

        if colored and colored.abbr_hl_group then
          vim_item.kind_hl_group = colored.abbr_hl_group
          vim_item.kind = colored.abbr
        end
      end

      -- Iconos y etiquetas de origen
      if lspkind_ok then
        vim_item = lspkind.cmp_format({
          mode = 'symbol_text',
          maxwidth = 50,
          ellipsis_char = '…',
          menu = {
            nvim_lsp = '[LSP]',
            luasnip = '[SNIP]',
            buffer = '[BUF]',
            path = '[PATH]',
            nvim_lua = '[LUA]',
          },
        })(entry, vim_item)
      end

      return vim_item
    end

    -- Comprobar si hay texto antes del cursor
    local function has_words_before()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))

      if col == 0 then
        return false
      end

      local text = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]

      return text:sub(col, col):match('%s') == nil
    end

    -- Ventana de autocompletado con bordes redondeados
    local function bordered()
      return cmp.config.window.bordered({
        border = 'rounded',
        winhighlight = 'NormalFloat:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None',
        scrolloff = 2,
      })
    end

    return {
      enabled = enabled,

      preselect = cmp.PreselectMode.None,

      completion = {
        completeopt = 'menu,menuone,noselect',
      },

      performance = {
        throttle = 20,
      },

      -- Ventanas
      window = {
        completion = bordered(),
        documentation = nil,
      },

      -- Integración LuaSnip
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },

      -- Atajos de teclado
      mapping = cmp.mapping.preset.insert({

        ['<C-e>'] = cmp.mapping.abort(),

        ['<C-Space>'] = cmp.mapping.complete(),

        ['<CR>'] = cmp.mapping.confirm({
          select = false,
        }),

        -- Siguiente sugerencia o snippet
        ['<Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { 'i', 's' }),

        -- Sugerencia anterior o snippet anterior
        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { 'i', 's' }),
      }),

      -- Formato de sugerencias
      formatting = {
        fields = {
          'kind',
          'abbr',
          'menu',
        },
        format = formatter,
      },

      -- Texto fantasma
      experimental = {
        ghost_text = {
          hl_group = 'Comment',
        },
      },

      -- Fuentes de autocompletado
      sources = cmp.config.sources({

        {
          name = 'nvim_lsp',
        },

        {
          name = 'luasnip',
        },

        {
          name = 'nvim_lua',
        },
      }, {

        {
          name = 'path',
        },

        {
          name = 'buffer',
          keyword_length = 4,
        },
      }),
    }
  end,

  config = function(_, opts)
    local cmp = require('cmp')

    cmp.setup(opts)

    --------------------------------------------------
    -- AUTOCOMPLETADO EN BÚSQUEDAS
    --------------------------------------------------

    cmp.setup.cmdline({ '/', '?' }, {
      mapping = cmp.mapping.preset.cmdline(),

      sources = {
        {
          name = 'buffer',
        },
      },
    })

    --------------------------------------------------
    -- AUTOCOMPLETADO EN COMANDOS
    --------------------------------------------------

    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),

      sources = cmp.config.sources({

        {
          name = 'path',
        },
      }, {

        {
          name = 'cmdline',
        },
      }),

      matching = {
        disallow_symbol_nonprefix_matching = false,
      },
    })

    --------------------------------------------------
    -- AUTOPAIRS
    -- La integración se configura en su propio plugin.
    --------------------------------------------------
  end,
}

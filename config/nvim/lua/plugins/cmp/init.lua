-- lua/plugins/cmp/init.lua
return {
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    -- fuentes básicas
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/cmp-nvim-lua', -- ← la necesitabas: usabas { name = "nvim_lua" }

    -- snippets
    {
      'L3MON4D3/LuaSnip',
      dependencies = {
        'rafamadriz/friendly-snippets',
        'benfowler/telescope-luasnip.nvim',
      },
      build = (function()
        -- build opcional para Windows (evita errores en no-Windows)
        return (vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1) and 'make install_jsregexp' or nil
      end)(),
    },
    'saadparwaiz1/cmp_luasnip',

    -- iconitos y colores bonitos (opcionales)
    'onsails/lspkind.nvim',
    'brenoprata10/nvim-highlight-colors',
  },
  opts = function()
    local cmp = require('cmp')
    local luasnip = require('luasnip')

    -- carga lazy de snippets VSCode
    pcall(function()
      require('luasnip.loaders.from_vscode').lazy_load()
    end)
    luasnip.config.set_config({
      history = true,
      updateevents = 'TextChanged,TextChangedI',
      enable_autosnippets = true,
    })

    -- deshabilitar cmp en comentarios (pero permitir en comandos/cmdline)
    local ok_ctx, context = pcall(require, 'cmp.config.context')

    local function enabled()
      if vim.bo.buftype == 'prompt' then
        return false
      end
      if ok_ctx then
        if context.in_treesitter_capture('comment') == true or context.in_syntax_group('Comment') then
          return false
        end
      end
      return true
    end

    -- formateo: lspkind + nvim-highlight-colors (si están)
    local lspkind_ok, lspkind = pcall(require, 'lspkind')
    local nhc_ok, nhc = pcall(require, 'nvim-highlight-colors')

    local function formatter(entry, vim_item)
      -- primero colores en el abbr si es un color literal (#fff, rgb(), etc.)
      if nhc_ok then
        local colored = nhc.format(entry, { kind = vim_item.kind })
        if colored and colored.abbr_hl_group then
          vim_item.kind_hl_group = colored.abbr_hl_group
          vim_item.kind = colored.abbr
        end
      end
      -- luego iconos/simbolitos
      if lspkind_ok then
        vim_item = (lspkind.cmp_format({
          mode = 'symbol_text',
          maxwidth = 50,
          ellipsis_char = '…',
          menu = {
            nvim_lsp = '[LSP]',
            luasnip = '[SNIP]',
            buffer = '[BUF]',
            path = '[PATH]',
            nvim_lua = '[LUA]',
            codeium = '[AI]',
          },
        }))(entry, vim_item)
      end
      return vim_item
    end

    -- helper: hay palabra antes del cursor?
    local function has_words_before()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      if col == 0 then
        return false
      end
      local text = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
      return text:sub(col, col):match('%s') == nil
    end

    -- ventanas con borde
    local function bordered(win)
      return cmp.config.window.bordered({
        border = 'rounded',
        winhighlight = 'NormalFloat:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None',
        scrolloff = 2,
      })
    end

    return {
      enabled = enabled,
      preselect = cmp.PreselectMode.None,
      completion = { completeopt = 'menu,menuone,noselect' },
      performance = { throttle = 20 },

      window = {
        completion = bordered('completion'),
        documentation = bordered('documentation'),
      },

      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },

      mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<C-Space>'] = cmp.mapping.complete(),

        ['<CR>'] = cmp.mapping.confirm({ select = true }),

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

      formatting = {
        fields = { 'kind', 'abbr', 'menu' },
        format = formatter,
      },

      experimental = {
        ghost_text = { hl_group = 'Comment' },
      },

      sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'nvim_lua' },
        -- fuentes opcionales: se usarán sólo si el plugin existe
        { name = 'codeium', max_item_count = 5, group_index = 2 },
      }, {
        { name = 'path' },
        { name = 'buffer', keyword_length = 3 },
        { name = 'render-markdown' },
      }),
    }
  end,
  config = function(_, opts)
    local cmp = require('cmp')
    cmp.setup(opts)

    -- Nota: la integración con autopairs ya la enganchamos en el plugin de autopairs.
    -- Si no la tuvieras allí, podrías descomentar:
    -- local cmp_autopairs = require("nvim-autopairs.completion.cmp")
    -- cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done({ map_char = { tex = "" } }))

    ------------------------------------------------------------------
    -- cmdline completion
    ------------------------------------------------------------------
    -- búsqueda con / y ?
    cmp.setup.cmdline({ '/', '?' }, {
      mapping = cmp.mapping.preset.cmdline(),
      sources = { { name = 'buffer' } },
    })

    -- comandos con :
    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = 'path' },
      }, {
        { name = 'cmdline' },
      }),
      -- evita completado en ejecuciones tipo :! o :Man
      matching = { disallow_symbol_nonprefix_matching = false },
    })
  end,
}

return {
  'hrsh7th/nvim-cmp',
  dependencies = {
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-path',
    'saadparwaiz1/cmp_luasnip',
    -- has configs
    { 'L3MON4D3/LuaSnip', dependencies = { 'rafamadriz/friendly-snippets', 'benfowler/telescope-luasnip.nvim' }, main = 'luasnip' },
  },
  event = 'InsertEnter',
  config = function()
    -- eyJhbGciOiJSUzI1NiIsImtpZCI6ImYyOThjZDA3NTlkOGNmN2JjZTZhZWNhODExNmU4ZjYzMDlhNDQwMjAiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiSm9uYXRoYW4uRCAuRCIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQWNIVHRkRWo5NDVpS0x5eUx0ZHVDcFY4bWQwdGUyZXVwaDZSLWRMX3dFbz1zOTYtYyIsImlzcyI6Imh0dHBzOi8vc2VjdXJldG9rZW4uZ29vZ2xlLmNvbS9leGEyLWZiMTcwIiwiYXVkIjoiZXhhMi1mYjE3MCIsImF1dGhfdGltZSI6MTcxMzA0NDMwMCwidXNlcl9pZCI6Ik1pTlVzMHExOTBWemJjOW50RldVc2RjaXJ6QjMiLCJzdWIiOiJNaU5VczBxMTkwVnpiYzludEZXVXNkY2lyekIzIiwiaWF0IjoxNzEzMDQ0MzA0LCJleHAiOjE3MTMwNDc5MDQsImVtYWlsIjoiZG9uYXRoYW4uZC5kb21pbmd1ZXpAZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZ29vZ2xlLmNvbSI6WyIxMTY5NDYwODc2NDYzMDUxNzgzODkiXSwiZW1haWwiOlsiZG9uYXRoYW4uZC5kb21pbmd1ZXpAZ21haWwuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoiZ29vZ2xlLmNvbSJ9fQ.ZJZgkryGaDQX3izEoTC5qsy4JitL_hQ-0I2zeyouUznL4zxEMN5tGRjkQCpUjufblVynlFDON6XI94LE_-Zh4evGJourRTcirg6dKG9LNRERq_aaDrZGb1yTWRW-TQwgtiuXEtN-Cm8Vt-AxB1BSk9-1g2yJd7JdxZBdmnYxwgmRP0iYtll1_AXJXb4t4VeFHdukkcvVftMfzJhzL658qJINI3c95Wf1YkKEfkn8YewZ2OD13w_-uqoCw-G2CMCkiDOAgagNkDvtW9KiYyXxADgsz8Nn_3QU3r64v9M2OToI9Pyjdbp--cjceqJfqzvoddvE-QpLqRV368wzcKDkrww
    local function has_words_before()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
    end
    local cmp = require('cmp')
    local luasnip = require('luasnip')

    local cmp_autopairs = require('nvim-autopairs.completion.cmp')
    local icons = {
      kind = require('utils.icons').get('kind'),
      type = require('utils.icons').get('type'),
      cmp = require('utils.icons').get('cmp'),
    }
    cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
    cmp.setup({
      snippet = {
        expand = function(args)
          require('luasnip').lsp_expand(args.body)
        end,
      },
      -- sorting = {
      --   priority_weight = 2,
      --   comparators = {
      --     cmp.config.compare.offset,
      --     cmp.config.compare.exact,
      --     cmp.config.compare.score,
      --     cmp.config.compare.recently_used,
      --     cmp.config.compare.locality,
      --     cmp.config.compare.kind,
      --     cmp.config.compare.sort_text,
      --     cmp.config.compare.length,
      --     cmp.config.compare.order,
      --   },
      -- },

      preselect = cmp.PreselectMode.Item,

      formatting = {
        format = function(entry, vim_item)
          -- Aplicar nvim-highlight-colors primero
          local color_item = require('nvim-highlight-colors').format(entry, { kind = vim_item.kind })

          -- Aplicar lspkind si está disponible
          vim_item = require('lspkind').cmp_format({})(entry, vim_item)

          -- Integración de colores con lspkind
          if color_item.abbr_hl_group then
            vim_item.kind_hl_group = color_item.abbr_hl_group
            vim_item.kind = color_item.abbr
          end

          return vim_item
        end,
      },

      mapping = {
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
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
      },

      sources = cmp.config.sources({
        { name = 'luasnip' },
        { name = 'nvim_lsp' },
        { name = 'codeium' },
        { name = 'buffer' },
        { name = 'nvim_lua' },
        { name = 'path' },
        { name = 'render-markdown' },
      }),
    })
  end,
}

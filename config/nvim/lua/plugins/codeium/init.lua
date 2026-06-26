return {
  'hrsh7th/nvim-cmp',
  dependencies = {
    {
      'Exafunction/codeium.nvim',
      dependencies = { 'nvim-lua/plenary.nvim' },
      -- Para que esté disponible cuando cmp se inicie (no solo con :Codeium)
      event = 'InsertEnter',
      build = ':Codeium Auth', -- deja esto si querés que te guíe en el login
      opts = {}, -- tus prefs si querés
      config = function(_, opts)
        local ok = pcall(require, 'codeium')
        if ok then
          require('codeium').setup(opts)
        end
      end,
    },
  },

  -- extiende la config existente de cmp sin romper lo que ya tengas
  opts = function(_, opts)
    opts.sources = opts.sources or {}

    -- evita insertar duplicados
    local has_codeium = false
    for _, s in ipairs(opts.sources) do
      if s.name == 'codeium' then
        has_codeium = true
        break
      end
    end
    if not has_codeium then
      table.insert(opts.sources, 1, {
        name = 'codeium',
        group_index = 2,
        priority = 90,
        max_item_count = 5,
      })
    end

    -- (opcional) orden: da prioridad a LSP sobre AI, dejando AI después
    -- Solo añade si no definiste tus comparators
    if not opts.sorting or not opts.sorting.comparators then
      local cmp = require('cmp')
      opts.sorting = {
        priority_weight = 1.0,
        comparators = {
          cmp.config.compare.offset,
          cmp.config.compare.exact,
          cmp.config.compare.score,
          -- de-prioriza AI un poco frente a LSP
          function(a, b)
            local ai_a = (a.source.name == 'codeium') and 1 or 0
            local ai_b = (b.source.name == 'codeium') and 1 or 0
            if ai_a ~= ai_b then
              return ai_a < ai_b
            end
          end,
          cmp.config.compare.recently_used,
          cmp.config.compare.locality,
          cmp.config.compare.kind,
          cmp.config.compare.sort_text,
          cmp.config.compare.length,
          cmp.config.compare.order,
        },
      }
    end

    return opts
  end,
}

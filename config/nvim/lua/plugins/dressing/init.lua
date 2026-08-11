-- lua/plugins/dressing/init.lua
local M = {
  'stevearc/dressing.nvim',
  event = 'VeryLazy',
  dependencies = { 'MunifTanjim/nui.nvim' },
  opts = function()
    return {
      input = {
        enabled = true,
        prompt_align = 'left',
        prefer_width = 40,
        insert_only = true,
        start_in_insert = true,
        relative = 'editor',
        border = 'rounded',
        win_options = {
          winhighlight = 'NormalFloat:NormalFloat,FloatBorder:FloatBorder',
          -- winblend = 0, -- activa si querés transparencia
        },
        get_config = function(opts)
          if opts and opts.kind == 'rename' then
            return { relative = 'cursor', prefer_width = 40, border = 'rounded' }
          end
        end,
      },
      select = {
        enabled = true,
        -- ⚠️ orden fijo; evita require('telescope') en opts
        backend = { 'nui', 'telescope', 'builtin' },
        trim_prompt = true,
        telescope = { theme = 'cursor' },
        nui = {
          relative = 'editor',
          position = '50%',
          size = nil,
          border = { style = 'rounded' },
          max_width = 0.5,
          max_height = 0.6,
        },
        get_config = function(opts)
          if opts and opts.kind == 'codeaction' then
            return {
              backend = 'nui',
              nui = { relative = 'cursor', max_width = 60, border = { style = 'rounded' } },
            }
          end
        end,
      },
    }
  end,
  config = function(_, opts)
    -- (opcional) evita inicializar sin UI o en diff
    if #vim.api.nvim_list_uis() == 0 or vim.wo.diff then
      return
    end
    require('dressing').setup(opts)
  end,
}

return M

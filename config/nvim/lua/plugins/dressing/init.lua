-- lua/plugins/dressing/init.lua
local M = {
  'stevearc/dressing.nvim',
  event = 'VeryLazy',
  dependencies = { 'MunifTanjim/nui.nvim' },
  opts = function()
    local function has(mod)
      return pcall(require, mod)
    end

    -- backends preferidos para select (se elige el 1º disponible)
    local select_backends = { 'nui' }
    if has('telescope') then
      table.insert(select_backends, 'telescope')
    end
    table.insert(select_backends, 'builtin')

    return {
      -------------------------------------------------------------------
      -- ui.input (rename, prompts, etc.)
      -------------------------------------------------------------------
      input = {
        enabled = true,
        prompt_align = 'left',
        prefer_width = 40,
        insert_only = true,
        start_in_insert = true,
        relative = 'editor',
        border = 'rounded',
        win_options = {
          -- Cambiá esto si querés otro highlight:
          winhighlight = 'NormalFloat:NormalFloat,FloatBorder:FloatBorder',
        },
        -- Para LSP rename, mostrar cerca del cursor
        get_config = function(opts)
          if opts and opts.kind == 'rename' then
            return { relative = 'cursor', prefer_width = 40, border = 'rounded' }
          end
        end,
      },

      -------------------------------------------------------------------
      -- ui.select (code actions, pickers genéricos)
      -------------------------------------------------------------------
      select = {
        enabled = true,
        backend = select_backends, -- {"nui", "telescope", "builtin"} según disponibilidad
        trim_prompt = true,

        telescope = {
          theme = 'cursor',
        },

        nui = {
          relative = 'editor',
          position = '50%',
          size = nil, -- auto
          border = { style = 'rounded' },
          max_width = 0.5,
          max_height = 0.6,
        },

        -- Casos especiales
        get_config = function(opts)
          if opts and opts.kind == 'codeaction' then
            return {
              backend = 'nui',
              nui = {
                relative = 'cursor',
                max_width = 60,
                border = { style = 'rounded' },
              },
            }
          end
        end,
      },
    }
  end,
}

M.config = function(_, opts)
  require('dressing').setup(opts)
end

return M

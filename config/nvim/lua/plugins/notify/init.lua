-- lua/plugins/notify/init.lua
local M = {
  'rcarriga/nvim-notify',
  event = 'VeryLazy',
  keys = {
    {
      '<leader>un',
      function()
        require('notify').dismiss({ silent = true, pending = true })
      end,
      desc = 'Notificaciones: descartar',
    },
    { '<leader>sn', '<cmd>Notifications<cr>', desc = 'Notificaciones: historial' },
    -- Si usás Telescope: :Telescope notify
  },
  opts = function()
    local icons
    pcall(function()
      icons = require('utils.icons').icons
    end) -- fallback si no existe

    -- Fondo por defecto (no pisa el tema si ya lo define)
    vim.api.nvim_set_hl(0, 'NotifyBackground', { bg = '#000000', default = true })

    return {
      stages = 'fade_in_slide_out',
      render = 'compact',
      top_down = false,
      fps = 60,
      background_colour = 'NotifyBackground',
      timeout = 2000,
      max_width = function()
        return math.floor(vim.o.columns * 0.38)
      end,
      max_height = function()
        return math.floor(vim.o.lines * 0.30)
      end,
      icons = icons,
      -- distintos timeouts por nivel (opcional)
      level = 0, -- muestra todo; ajusta a :help vim.log.levels
      on_open = function(win)
        -- bordes redondeados si tu UI los soporta
        pcall(vim.api.nvim_win_set_config, win, { border = 'rounded' })
      end,
    }
  end,
  -- No sobreescribir vim.notify: noice ya lo rutea a nvim-notify cuando
  -- notify.enabled = true (ver plugins/noice/init.lua).
}

M.config = function(_, opts)
  -- guardas: no inicializar sin UI o en diff
  if #vim.api.nvim_list_uis() == 0 or vim.wo.diff then
    return
  end

  require('notify').setup(opts)

  -- Telescope (si está): :Telescope notify
  pcall(function()
    require('telescope').load_extension('notify')
  end)
end

return M

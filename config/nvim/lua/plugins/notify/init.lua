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
  },
  opts = function()
    local icons
    pcall(function()
      icons = require('utils.icons').icons
    end) -- fallback si no existe
    return {
      background_colour = '#000000',
      stages = 'fade_in_slide_out',
      render = 'compact',
      timeout = 2000,
      top_down = false,
      fps = 60,
      max_width = function()
        return math.floor(vim.o.columns * 0.38)
      end,
      max_height = function()
        return math.floor(vim.o.lines * 0.30)
      end,
      icons = icons,
    }
  end,
}

M.config = function(_, opts)
  local notify = require('notify')
  notify.setup(opts)
  vim.notify = notify
  -- opcional: integra con telescope si está
  pcall(function()
    require('telescope').load_extension('notify')
  end)
end

return M

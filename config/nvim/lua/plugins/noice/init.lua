return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'rcarriga/nvim-notify',
  },
  config = function()
    local has_notify = pcall(require, 'notify')

    require('noice').setup({
      -- Mensajes y notificaciones
      messages = {
        view = 'mini',
        view_error = has_notify and 'notify' or 'mini',
        view_warn = has_notify and 'notify' or 'mini',
        view_search = false,
      },

      notify = {
        enabled = has_notify,
        view = 'notify',
      },

      -- Línea de comandos y búsquedas
      cmdline = {
        view = 'cmdline_popup',
        format = {
          cmdline = { icon = '' },
          search_down = { icon = ' ' },
          search_up = { icon = ' ' },
          filter = { icon = '$' },
          lua = { icon = '' },
          help = { icon = '󰋖' },
        },
      },

      views = {
        cmdline_popup = {
          position = { row = '35%', col = '50%' },
          size = { width = 60, height = 'auto' },
          border = { style = 'rounded' },
        },
        popupmenu = {
          relative = 'editor',
          position = { row = '45%', col = '50%' },
          size = { width = 60, height = 10 },
          border = { style = 'rounded' },
          win_options = { winblend = 0 },
        },
        mini = { timeout = 2000 },
      },

      -- LSP
      lsp = {
        -- Noice es ahora el único lugar donde se muestra el progreso LSP
        -- (antes fidget.nvim duplicaba esta tarea).
        progress = { enabled = true, view = 'mini' },
        hover = { enabled = true, silent = true },
        signature = {
          enabled = true,
          -- auto_open apagado: noice abría el popup de firma/documentación
          -- solo al escribir "(" (p. ej. autocmd(). La firma manual sigue
          -- disponible con gK.
          auto_open = { enabled = false },
        },
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
      },

      -- Presets
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },

      -- 🔥 FILTROS (routes)
      routes = {
        -- Oculta mensajes molestos comunes
        { filter = { event = 'msg_show', kind = 'search_count' }, opts = { skip = true } },
        { filter = { event = 'msg_show', find = 'written' }, opts = { skip = true } },
        { filter = { event = 'msg_show', find = 'lines? yanked' }, view = 'mini' },
        { filter = { event = 'msg_show', find = 'fewer lines' }, opts = { skip = true } },

        -- Mensajes largos a split
        {
          filter = {
            min_width = 80,
            any = {
              { event = 'msg_show' },
              { event = 'notify' },
            },
          },
          view = 'split',
        },
      },

      throttle = 60,
    })

    -- Scroll en popups LSP
    local function map_scroll(lhs, delta)
      for _, mode in ipairs({ 'n', 'i', 's' }) do
        vim.keymap.set(mode, lhs, function()
          local ok = require('noice.lsp').scroll(delta)
          if not ok then
            return lhs
          end
        end, { silent = true, expr = true, desc = 'Noice scroll' })
      end
    end

    pcall(map_scroll, '<C-f>', 4)
    pcall(map_scroll, '<C-b>', -4)
  end,
}

-- lua/plugins/comment/init.lua
return {
  'numToStr/Comment.nvim',
  event = 'VeryLazy',
  dependencies = {
    -- Comentarios contextuales para JSX/TSX/Vue/Svelte, etc.
    'JoosepAlviste/nvim-ts-context-commentstring',
  },
  config = function()
    local comment = require('Comment')

    -- Integra commentstring contextual si el plugin está disponible
    local pre_ok, pre_hook = pcall(function()
      return require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()
    end)

    comment.setup({
      padding = true, -- espacio entre // y el texto
      sticky = true, -- mantener selección tras comentar con visual
      ignore = '^$', -- no comentar líneas vacías
      mappings = {
        basic = true, -- gcc, gc, gbc, gb
        extra = true, -- gco, gcO, gcA
        extended = false, -- no necesitamos extra raros
      },
      toggler = {
        line = 'gcc',
        block = 'gbc',
      },
      opleader = {
        line = 'gc',
        block = 'gb',
      },
      pre_hook = pre_ok and pre_hook or nil, -- usa commentstring contextual cuando aplique
    })

    -- Overrides de filetypes (opcionales). YAML ya usa '#', pero forzamos con espacio:
    local ft = require('Comment.ft')
    ft.set('yaml', '# %s')

    -- No seteamos JS/TS manualmente: lo maneja ts-context-commentstring según el contexto
    -- (por ejemplo, JSX dentro de TSX, <style> en Svelte, etc.)
  end,
}

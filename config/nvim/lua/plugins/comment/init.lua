-- lua/plugins/comment/init.lua
return {
  'numToStr/Comment.nvim',
  event = 'VeryLazy',
  dependencies = {
    {
      'JoosepAlviste/nvim-ts-context-commentstring',
      opts = { enable_autocmd = false }, -- ⚠️ necesario si usás pre_hook
    },
  },
  config = function()
    local comment = require('Comment')

    -- Integra commentstring contextual si está disponible
    local pre_ok, pre_hook = pcall(function()
      return require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()
    end)

    comment.setup({
      padding = true, -- espacio entre // y el texto
      sticky = true, -- mantiene selección tras comentar en visual
      ignore = '^$', -- no comenta líneas vacías
      mappings = {
        basic = true, -- gcc, gc, gbc, gb (poné false si no los querés)
        extra = true, -- gco, gcO, gcA
        extended = false,
      },
      toggler = { line = 'gcc', block = 'gbc' },
      opleader = { line = 'gc', block = 'gb' },
      pre_hook = pre_ok and pre_hook or nil, -- usa commentstring contextual
    })

    -- Overrides de filetypes (ejemplo). YAML ya usa '#', pero con espacio queda más prolijo.
    local ft = require('Comment.ft')
    ft.set('yaml', '# %s')
    -- No seteamos JS/TS manualmente: lo maneja ts-context-commentstring por contexto (JSX, <style> de Svelte, etc.).
  end,
}

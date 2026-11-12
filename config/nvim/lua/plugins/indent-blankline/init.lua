local M = {
  'lukas-reineke/indent-blankline.nvim',
  -- desde ibl v3, el módulo principal es "ibl"
  event = { 'BufReadPost', 'BufNewFile' },
}

M.config = function()
  -- highlights amigables con cualquier tema (solo si no existen)
  vim.api.nvim_set_hl(0, 'IBLIndent', { link = 'LineNr', default = true })
  vim.api.nvim_set_hl(0, 'IBLScope', { link = 'Function', default = true })

  -- Desactivar en archivos grandes usando la marca que pone config/autocmd.lua
  -- (política única de tamaño).
  local function disable_for_large_file(buf)
    if not vim.b[buf].large_file then
      return
    end

    local ok_ibl, ibl = pcall(require, 'ibl')
    if ok_ibl then
      ibl.setup_buffer(buf, { enabled = false })
    end
  end

  local ibl_group = vim.api.nvim_create_augroup('ibl_large_file', { clear = true })
  vim.api.nvim_create_autocmd('BufReadPost', {
    group = ibl_group,
    callback = function(args)
      disable_for_large_file(args.buf)
    end,
  })

  -- ibl ya hace pcall(vim.treesitter.get_parser) y no dibuja scope si el parser
  -- no existe; no hace falta una guarda propia ni una lista de nodos custom.
  require('ibl').setup({
    indent = {
      char = '▏',
      highlight = { 'IBLIndent' },
    },
    whitespace = {
      remove_blankline_trail = true,
    },
    scope = {
      enabled = true,
      injected_languages = false,
      highlight = { 'IBLScope' },
    },
    exclude = {
      filetypes = {
        'help',
        'lazy',
        'mason',
        'oil',
        'TelescopePrompt',
        'alpha',
        'dashboard',
        'gitcommit',
        'markdown',
        'text',
        'Trouble',
      },
      buftypes = { 'nofile', 'terminal', 'prompt' },
    },
  })

  -- El BufReadPost que cargó ibl ya ocurrió, así que el autocmd recién creado
  -- no se dispara para el primer buffer: aplicamos el estado a mano.
  vim.schedule(function()
    disable_for_large_file(vim.api.nvim_get_current_buf())
  end)
end

return M

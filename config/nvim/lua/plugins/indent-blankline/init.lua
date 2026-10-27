local M = {
  'lukas-reineke/indent-blankline.nvim',
  -- desde ibl v3, el módulo principal es "ibl"
  event = { 'BufReadPost', 'BufNewFile' },
}

M.config = function()
  -- highlights amigables con cualquier tema (solo si no existen)
  vim.api.nvim_set_hl(0, 'IBLIndent', { link = 'LineNr', default = true })
  vim.api.nvim_set_hl(0, 'IBLScope', { link = 'Function', default = true })

  -- desactivar en archivos muy grandes (>1MB) para evitar lag
  local ibl_group = vim.api.nvim_create_augroup('ibl_large_file', { clear = true })
  vim.api.nvim_create_autocmd('BufReadPost', {
    group = ibl_group,
    callback = function(args)
      local ok, stat = pcall(vim.uv.fs_stat, args.file)
      if ok and stat and stat.size > 1024 * 1024 then
        local ok_ibl, ibl = pcall(require, 'ibl')
        if ok_ibl then
          ibl.setup_buffer(0, { enabled = false })
        end
      end
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
end

return M

local M = {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
}

M.config = function()
  local conform = require('conform')

  conform.setup({
    formatters_by_ft = {
      c = { name = 'clangd', timeout_ms = 500, lsp_format = 'prefer' },
      javascript = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
      javascriptreact = { 'prettierd' },
      json = { 'prettier' },
      jsonc = { 'prettier', stop_on_first = true, name = 'dprint', timeout_ms = 500 },
      less = { 'prettier' },
      lua = { 'stylua' },
      markdown = { 'prettierd' },
      rust = { name = 'rust_analyzer', timeout_ms = 500, lsp_format = 'prefer' },
      scss = { 'prettier' },
      sh = { 'shfmt' },
      typescript = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
      typescriptreact = { 'prettierd' },
      css = { 'prettierd' },
      html = { 'prettierd' },
      yaml = { 'prettierd' },
      graphql = { 'prettierd' },
      razor = { 'prettierd' },
      python = { 'autopep8' },
      c_sharp = { 'csharpier' },
      go = { 'goimports', 'gofumpt' },
      ['_'] = { 'trim_whitespace', 'trim_newlines' },
      -- Use the "*" filetype to run formatters on all filetypes.
      ['*'] = { 'codespell' },
    },

    format_after_save = {
      lsp_fallback = true,
      async = true,
      condition = function()
        if vim.g.minifiles_active then
          return false
        end
        if not vim.g.autoformat then
          return false
        end
        return true
      end,
    },
  })

  vim.keymap.set({ 'n', 'v' }, '<S-f>', function()
    conform.format({
      lsp_fallback = true,
      async = true,
    })
  end, { desc = 'Format file or range (in visual mode)' })
end

M.init = function()
  vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  vim.g.autoformat = true
end

return M

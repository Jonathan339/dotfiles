-- luacheck: push ignore
local v = vim
-- luacheck: pop

return {
  'stevearc/conform.nvim',
  event = 'BufWritePre',
  lazy = false,
  opts = {
    formatters_by_ft = {
      dart = { 'dart_format' },
      elm = { 'elm_format' },
      go = { 'gofumpt' },
      htmldjango = { 'djlint', 'rustywind' },
      lua = { 'stylua' },
      python = { 'ruff_fix', 'ruff_format' },
      rust = { 'rustfmt' },
      sh = { 'shfmt' },
      sql = { 'sql_formatter' },
      zig = { 'zigfmt' },
      -- prettier
      css = { 'prettier' },
      graphql = { 'prettier' },
      json = { 'prettier' },
      less = { 'prettier' },
      markdown = { 'prettier' },
      scss = { 'prettier' },
      toml = { 'prettier' },
      vue = { 'prettier' },
      yaml = { 'prettier' },
      javascript = { 'prettier', 'rustywind' },
      javascriptreact = { 'prettier', 'rustywind' },
      typescript = { 'prettier', 'rustywind' },
      typescriptreact = { 'prettier', 'rustywind' },

      -- rest
      ['*'] = { 'trim_whitespace', 'trim_newlines', 'codespell' },
    },
    format_on_save = function(bufnr)
      local disable_filetypes = { c = true, cpp = true }
      return {
        timeout_ms = 1000,
        lsp_fallback = not disable_filetypes[v.bo[bufnr].filetype],
      }
    end,
    formatters = {
      ruff_fix = {
        prepend_args = {
          'check',
          '--ignore=F401',       -- unused-import
          '--unfixable=B007',    -- unused-loop-control-variable
          '--unfixable=C411',    -- unnecessary-list-call
          '--unfixable=C416',    -- unnecessary-comprehension
          '--unfixable=F601',    -- multi-value-repeated-key-literal
          '--unfixable=F841',    -- unused-variable
          '--unfixable=PIE794',  -- duplicated-class-field-definition
          '--unfixable=PLR5501', -- collapsible-else-if
          '--unfixable=PT014',   -- pytest-duplicate-parametrize-test-cases
          '--unfixable=RET504',  -- unnecessary-assign
          '--unfixable=SIM102',  -- collapsible-if
          '--unfixable=PYI016',  -- duplicate-union-member
          '--unfixable=SIM105',  -- suppressible-exception
          '--unfixable=SIM114',  -- if-with-same-arms
          '--unfixable=T201',    -- print
        },
      },
    },
    notify_on_error = true,
  },
}

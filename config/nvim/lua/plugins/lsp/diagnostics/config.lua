local u = require('utils.init')
local user_config = require('config.user')

-- intenta cargar icons, si no hay, usa defaults simples
local ok, icons_mod = pcall(require, 'utils.icons')
local icons = ok and icons_mod.get('diagnostics') or {
  Debug = '',
  Circle = '●',
  Error = '',
  Warning = '',
  Information = '',
  Hint = '',
}

local default_diagnostic_config = {
  underline = true,
  update_in_insert = true,
  severity_sort = true,
  float = {
    border = 'rounded',
    focusable = true,
    header = { icons.Debug .. ' Diagnostics:', 'DiagnosticInfo' },
    scope = 'line',
    suffix = '',
    source = 'always',
  },
  -- ⚠️ solo activar si tenés plugin lsp_lines
  virtual_lines = false,
  virtual_text = {
    prefix = icons.Circle,
    spacing = 2,
    source = 'always',
    -- severity = { min = vim.diagnostic.severity.HINT },
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = icons.Error,
      [vim.diagnostic.severity.WARN] = icons.Warning,
      [vim.diagnostic.severity.INFO] = icons.Information,
      [vim.diagnostic.severity.HINT] = icons.Hint,
    },
    linehl = {
      [vim.diagnostic.severity.ERROR] = 'ErrorMsg',
    },
    numhl = {
      [vim.diagnostic.severity.WARN] = 'WarningMsg',
    },
  },
}

-- Fusionar con config de usuario
local config = u.merge(default_diagnostic_config, user_config.diagnostic or {})

return config

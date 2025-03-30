local u = require('utils')
local user_config = require('config.user')
local icons = require('utils.icons').get('diagnostics')
local config = {}

local default_diagnostic_config = {
  underline = true,
  update_in_insert = true,
  severity_sort = false,
  float = {
    border = 'rounded',
    focusable = true,
    header = { icons.Debug .. ' Diagnostics:', 'DiagnosticInfo' },
    scope = 'line',
    suffix = '',
    source = 'always',
  },
  virtual_text = {
    prefix = icons.Circle,
    spacing = 2,
    source = 'always',
    -- severity = {
    --   min = vim.diagnostic.severity.HINT,
    -- },
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

-- Fusionar configuración predeterminada con la del usuario
config = u.merge(default_diagnostic_config, user_config.diagnostic or {})

-- Devolver configuración para ser utilizada en otro lugar
return config

local ok, lsp_defaults = pcall(require, 'plugins.lsp.defaults')
local user_config = {}

if not ok then
  lsp_defaults = {}
end

local default_config = {
  border = 'rounded',
  disable_builtin_plugins = {},
  lsp = {
    inlay_hint = true,
    format_on_save = true,
    format_timeout = 500,
    rename_notification = true,
    on_attach = lsp_defaults.on_attach,
    ensure_installed = lsp_defaults.ensure_installed,
    servers = lsp_defaults.servers or {},
  },
  plugins = {
    luasnip = {
      history = true,
      updateevents = "TextChanged,TextChangedI",
      enable_autosnippets = true,
    }
  }
}

local u = require('utils')
local config = u.merge(default_config, user_config)

function config.lsp.add_on_attach_mapping(callback)
  if not config.lsp.on_attach_mappings then
    config.lsp.on_attach_mappings = {}
  end
  table.insert(config.lsp.on_attach_mappings, callback)
end

return config

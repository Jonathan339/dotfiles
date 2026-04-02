local M = {}

local function chain(default_cb, custom_cb)
  if not default_cb then
    return custom_cb
  end
  if not custom_cb then
    return default_cb
  end

  return function(...)
    default_cb(...)
    custom_cb(...)
  end
end

local function warn(msg)
  vim.schedule(function()
    vim.api.nvim_echo({ { msg, 'WarningMsg' } }, true, {})
  end)
end

function M.setup(server, config)
  config = config or {}

  if not (vim.lsp and vim.lsp.config and vim.lsp.enable) then
    warn('[lsp.setup] Requires Neovim 0.11+ (vim.lsp.config / vim.lsp.enable)')
    return
  end

  local ok_defaults, defaults = pcall(require, 'plugins.lsp.defaults')
  if not ok_defaults then
    defaults = {}
  end

  local merged = vim.tbl_deep_extend('force', {
    capabilities = defaults.capabilities,
  }, config)

  merged.on_attach = chain(defaults.on_attach, config.on_attach)
  merged.on_init = chain(defaults.on_init, config.on_init)

  local ok_configure, err = pcall(vim.lsp.config, server, merged)
  if not ok_configure then
    warn(('[lsp.setup] Failed configuring %s: %s'):format(server, tostring(err)))
    return
  end

  local ok_enable, enable_err = pcall(vim.lsp.enable, server)
  if not ok_enable then
    warn(('[lsp.setup] Failed enabling %s: %s'):format(server, tostring(enable_err)))
  end
end

return M

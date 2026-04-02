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
    local ok = pcall(vim.notify, msg, vim.log.levels.WARN)
    if not ok then
      vim.api.nvim_echo({ { msg, 'WarningMsg' } }, true, {})
    end
  end)
end

function M.setup(server, config)
  config = config or {}

  local ok_lspconfig, lspconfig = pcall(require, 'lspconfig')
  if not ok_lspconfig then
    warn('[lsp.setup] Unable to load lspconfig for ' .. server)
    return
  end

  local ok_defaults, defaults = pcall(require, 'plugins.lsp.defaults')
  if not ok_defaults then
    defaults = {}
  end

  local client = lspconfig[server]
  if not client then
    warn(('[lsp.setup] Unknown server: %s'):format(server))
    return
  end

  local merged = vim.tbl_deep_extend('force', {
    capabilities = defaults.capabilities,
  }, config)

  merged.on_attach = chain(defaults.on_attach, config.on_attach)
  merged.on_init = chain(defaults.on_init, config.on_init)

  client.setup(merged)
end

return M

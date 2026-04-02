local M = {}

local lspconfig = require("lspconfig")
local defaults = require("plugins.lsp.defaults")

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

function M.setup(server, config)
  config = config or {}

  local client = lspconfig[server]
  if not client then
    vim.schedule(function()
      vim.notify(("[lsp.setup] Unknown server: %s"):format(server), vim.log.levels.WARN)
    end)
    return
  end

  local merged = vim.tbl_deep_extend("force", {
    capabilities = defaults.capabilities,
  }, config)

  merged.on_attach = chain(defaults.on_attach, config.on_attach)
  merged.on_init = chain(defaults.on_init, config.on_init)

  client.setup(merged)
end

return M

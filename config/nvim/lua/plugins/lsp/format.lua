local M = {}

-- Conform es el único formateador de la config (por eso conform/init.lua va
-- con lsp_fallback = false). Quitamos las capacidades de formato del LSP para
-- que no haya dos caminos distintos de formatear el mismo buffer.
M.on_attach = function(client, _)
  if not client or not client.server_capabilities then return end
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false
end

return M

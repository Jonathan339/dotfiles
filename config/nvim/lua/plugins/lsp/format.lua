local M = {}

M.on_attach = function(client, bufnr)
	if not client or not client.server_capabilities then return end
	client.server_capabilities.documentFormattingProvider = false
	client.server_capabilities.documentRangeFormattingProvider = false
end

return M

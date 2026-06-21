---@diagnostic disable: undefined-global
local M = {}

-- Cacheamos el grupo de autocomandos y el estado de conform una sola vez al cargar el archivo
local group = vim.api.nvim_create_augroup("LspFormatting", { clear = true })
local ok_conform, conform = pcall(require, "conform")

M.on_attach = function(client, bufnr)
	if not client or not bufnr then
		return
	end

	-- Si usamos Conform, desactivamos el formateo del LSP para evitar doble formato
	if ok_conform then
		if client.server_capabilities then
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
		end
		-- Si Conform está activo, él se encarga del formateo en el guardado (BufWritePre).
		-- Salimos temprano y evitamos crear autocomandos innecesarios.
		return
	end

	-- =========================================================================
	-- FALLBACK: Si no existe Conform, usamos el formateo nativo de LSP
	-- =========================================================================

	-- Limpiamos autocmds previos del buffer para evitar duplicados si el LSP se reinicia
	vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })

	if client.supports_method("textDocument/formatting") then
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = group,
			buffer = bufnr,
			callback = function()
				-- Usamos pcall por seguridad si el buffer se cierra a mitad de un formateo síncrono
				pcall(vim.lsp.buf.format, { bufnr = bufnr, async = false, timeout_ms = 1000 })
			end,
		})
	end
end

return M

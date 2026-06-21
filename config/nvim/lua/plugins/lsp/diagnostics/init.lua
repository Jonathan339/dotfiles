local ok, diagnostics = pcall(require, "plugins.lsp.diagnostics.config")
if ok and diagnostics then
	-- 1. Ejecutamos el setup interno de forma segura (él ya aplica vim.diagnostic.config)
	diagnostics.setup()

	-- 2. Signos con íconos (Compatibilidad nativa y fallback mediante sign_define)
	local signs = {
		Error = " ",
		Warn = " ",
		Hint = " ",
		Info = " ",
	}
	for type, icon in pairs(signs) do
		local hl = "DiagnosticSign" .. type
		vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
	end
end

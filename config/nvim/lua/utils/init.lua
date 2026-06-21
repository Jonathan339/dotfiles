local M = {}

-- Cacheamos funciones nativas de alto rendimiento para evitar Lookups en cada mapeo
local tbl_deep_extend = vim.tbl_deep_extend
local keymap_set = vim.keymap.set

---@param server string Nombre del servidor LSP (ej: "ts_ls", "lua_ls")
---@param config table|nil Configuración específica del handler
M.setup_lsp = function(server, config)
	-- Hacemos require bajo demanda (Lazy) solo cuando se llama a setup_lsp.
	-- Esto rompe cualquier dependencia circular y acelera el arranque.
	local ok_lsp, lspconfig = pcall(require, "lspconfig")
	local ok_defaults, defaults = pcall(require, "plugins.lsp.defaults")

	if not ok_lsp then
		vim.notify("Error: 'lspconfig' no encontrado al configurar " .. server, vim.log.levels.ERROR)
		return
	end

	-- Si por alguna razón defaults no cargó, creamos una tabla vacía segura para evitar crashes
	if not ok_defaults then
		defaults = { capabilities = {}, on_attach = nil, on_init = nil }
	end

	lspconfig[server].setup(tbl_deep_extend("force", {
		capabilities = defaults.capabilities,
		on_attach = defaults.on_attach,
		on_init = defaults.on_init,
	}, config or {}))
end

---Mapeo de teclas global seguro
M.map = function(mode, lhs, rhs, opts)
	keymap_set(
		mode,
		lhs,
		rhs,
		tbl_deep_extend("force", { silent = true, noremap = true }, opts or {})
	)
end

---Creador de mapeos locales a un buffer específico (ideal para LspAttach)
M.create_buf_map = function(bufnr, opts)
	return function(mode, lhs, rhs, map_opts)
		M.map(
			mode,
			lhs,
			rhs,
			tbl_deep_extend("force", { buffer = bufnr }, opts or {}, map_opts or {})
		)
	end
end

return M

-- lua/plugins/lsp/defaults.lua
local M = {}

-- Cacheamos el módulo de formateo una sola vez al cargar el archivo (mejora performance)
local ok_format, formatter = pcall(require, "plugins.lsp.format")

-- Esta lista es para mason-tool-installer (IDs de Mason, no nombres de lspconfig)
M.ensure_installed = {
	-- ===== LSP servers =====
	"emmet-language-server",
	"bash-language-server",
	"css-lsp",
	"custom-elements-languageserver",
	"dockerfile-language-server",
	"efm",
	"vscode-eslint-language-server",
	"graphql-language-service-cli",
	"html-lsp",
	"htmx-lsp",
	"json-lsp",
	"lua-language-server",
	"pyright",
	"rust-analyzer",
	"spectral-language-server",
	"sqls",
	"typescript-language-server", -- para lspconfig "ts_ls"
	"tailwindcss-language-server",
	"typos-lsp",
	"vim-language-server",
	"vtsls",
	"vue-language-server", -- Actualizado: Volar es el estándar moderno para Vue 3 (reemplaza a vls)
	"yaml-language-server",
	"marksman",

	-- ===== Formatters / Linters / Tools =====
	"prettier",
	"prettierd",
	"stylelint",
	"shellcheck",
	"shfmt",
	"black",
	"isort",
	"stylua",
	"rubocop",
	"pint",
	"dprint",
	"fixjson",
	"autopep8",
	"goimports",
	"goimports-reviser",
	"gofumpt",
}

-- Capabilities: usar cmp_nvim_lsp si está; fallback a capabilities base
local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
local base_caps = vim.lsp.protocol.make_client_capabilities()
M.capabilities = ok_cmp and cmp_nvim_lsp.default_capabilities(base_caps) or base_caps

-- Ajustes finos de completionItem
M.capabilities.textDocument = M.capabilities.textDocument or {}
M.capabilities.textDocument.completion = M.capabilities.textDocument.completion or {}
M.capabilities.textDocument.completion.completionItem =
	vim.tbl_deep_extend("force", M.capabilities.textDocument.completion.completionItem or {}, {
		documentationFormat = { "markdown", "plaintext" },
		snippetSupport = true,
		preselectSupport = true,
		insertReplaceSupport = true,
		labelDetailsSupport = true,
		deprecatedSupport = true,
		commitCharactersSupport = true,
		tagSupport = { valueSet = { 1 } },
		resolveSupport = {
			properties = { "documentation", "detail", "additionalTextEdits" },
		},
	})

-- Desactivar semantic tokens global (evita choques visuales y problemas de performance con Treesitter)
M.on_init = function(client, _)
	if client.supports_method("textDocument/semanticTokens") then
		client.server_capabilities.semanticTokensProvider = nil
	end
end

-- on_attach: configuraciones por buffer
M.on_attach = function(client, bufnr)
	if not client or not bufnr then
		return
	end

	vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

	-- Ejecuta el formateador si el módulo se cargó correctamente arriba
	if ok_format and formatter.on_attach then
		formatter.on_attach(client, bufnr)
	end
end

-- Root genérico (se recomienda usar como fallback en tu lspconfig principal)
M.root_dir = function(fname)
	local util = require("lspconfig").util
	return util.root_pattern(
		".git",
		"tsconfig.base.json",
		"tsconfig.json",
		"package.json",
		".eslintrc.js",
		".eslintrc.cjs",
		".eslintrc.json",
		".eslintrc.yaml",
		".eslintrc.yml",
		"eslint.config.js",
		"eslint.config.cjs",
		"eslint.config.mjs",
		"eslint.config.ts"
	)(fname)
end

return M

-- lua/plugins/lsp/handlers.lua
local M = {}
local setup = require("utils").setup_lsp
local util = require("lspconfig.util")
local root_pattern = util.root_pattern

-- Cacheamos la API de loop/uv actual de forma segura para evitar llamadas redundantes
local uv = vim.uv or vim.loop

-- Cacheamos schemastore de forma global una única vez si está instalado
local has_schemastore, schemastore = pcall(require, "schemastore")
local json_schemas = has_schemastore and schemastore.json.schemas() or nil

-- Handler compartido para desactivar el formateo nativo del LSP (Evita duplicar lógica)
local function disable_formatting(client, _)
	if client and client.server_capabilities then
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
	end
end

-- dprint LSP (formatea y/o diagnostica con su config local)
M["dprint"] = function()
	setup("dprint", {
		cmd = { "dprint", "lsp" },
		filetypes = {
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"json",
			"jsonc",
			"markdown",
			"python",
			"toml",
			"rust",
			"roslyn",
			"graphql",
		},
		root_dir = root_pattern("dprint.json", ".dprint.json", "dprint.jsonc", ".dprint.jsonc"),
	})
end

-- EFM (agregador genérico) -> sin formato para no chocar con Conform
M["efm"] = function()
	setup("efm", {
		cmd = { "efm-langserver" },
		init_options = { documentFormatting = false, documentRangeFormatting = false },
		root_dir = root_pattern(".git", ".efm.json", ".efmrc", ".config/efm-langserver/config.yaml"),
		filetypes = {
			"python",
			"cpp",
			"lua",
			"javascript",
			"typescript",
			"javascriptreact",
			"typescriptreact",
			"html",
			"css",
			"scss",
			"json",
			"yaml",
			"markdown",
			"markdown.pandoc",
			"astro",
			"svelte",
		},
		settings = {
			rootMarkers = { ".git/" },
			lintDebounce = "500ms",
		},
	})
end

-- typos (spell checker multi-idioma por LSP)
M["typos_lsp"] = function()
	setup("typos_lsp", {
		cmd = { "typos-lsp", "--stdio" },
	})
end

-- JSON LS (con schemastore si está) — formatea via Conform
M["jsonls"] = function()
	setup("jsonls", {
		cmd = { "vscode-json-language-server", "--stdio" },
		filetypes = { "json", "jsonc" },
		settings = {
			json = {
				schemas = json_schemas,
				validate = { enable = true },
			},
		},
		on_attach = disable_formatting,
	})
end

-- TypeScript/JavaScript (ts_ls)
M["ts_ls"] = function()
	setup("ts_ls", {
		handlers = {
			["textDocument/definition"] = function(err, result, ctx, ...)
				if type(result) == "table" and #result > 1 then
					result = { result[1] }
				end
				vim.lsp.handlers["textDocument/definition"](err, result, ctx, ...)
			end,
		},
		root_dir = function(fname)
			return root_pattern("tsconfig.json", "jsconfig.json", "package.json")(fname)
				or util.find_git_ancestor(fname)
				or uv.cwd()
		end,
		settings = {
			typescript = {
				inlayHints = {
					includeInlayEnumMemberValueHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayParameterNameHints = "all",
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayVariableTypeHintsWhenTypeMatchesName = true,
				},
			},
			javascript = {
				inlayHints = {
					includeInlayEnumMemberValueHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayParameterNameHints = "all",
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayVariableTypeHintsWhenTypeMatchesName = true,
				},
			},
		},
		on_attach = function(client, bufnr)
			disable_formatting(client, bufnr)

			-- Modernización y simplificación de Inlay Hints para Neovim >= 0.10
			if vim.lsp.inlay_hint then
				pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
			end
		end,
	})
end

-- ESLint LSP (formato via eslint_d en Conform)
M["eslint"] = function()
	setup("eslint", {
		cmd = { "vscode-eslint-language-server", "--stdio" },
		root_dir = function(fname)
			return root_pattern(
				".eslintrc",
				".eslintrc.js",
				".eslintrc.cjs",
				".eslintrc.json",
				".eslintrc.yaml",
				".eslintrc.yml",
				"eslint.config.js",
				"eslint.config.cjs",
				"eslint.config.mjs",
				"eslint.config.ts",
				"package.json"
			)(fname) or util.find_git_ancestor(fname)
		end,
		filetypes = {
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"vue",
			"svelte",
			"astro",
		},
		settings = {
			codeAction = {
				disableRuleComment = { enable = true, location = "separateLine" },
				showDocumentation = { enable = true },
			},
			codeActionOnSave = { enable = false, mode = "all" },
			format = false,
			validate = "on",
			workingDirectory = { mode = "location" },
		},
		on_attach = disable_formatting,
	})
end

-- Lua (Neovim)
M["lua_ls"] = function()
	setup("lua_ls", {
		settings = {
			Lua = {
				runtime = { version = "LuaJIT" },
				diagnostics = {
					globals = { "vim", "it", "describe", "before_each", "after_each" },
				},
				workspace = {
					checkThirdParty = false,
					library = vim.api.nvim_get_runtime_file("", true),
				},
				format = { enable = false },
				telemetry = { enable = false },
				completion = { callSnippet = "Replace" },
			},
		},
		on_attach = disable_formatting,
	})
end

-- Compatibilidad hacia atrás
M["tsserver"] = function()
	return M["ts_ls"]()
end

return M

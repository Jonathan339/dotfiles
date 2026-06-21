-- Formateo con Conform: ordena eslint_d -> prettierd/prettier, isort+black, etc.
-- Incluye format_on_save con fallback a LSP, chequeo de tamaño y toggles.

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo", "Format", "FormatToggle" },
	config = function()
		local conform = require("conform")
		local util = require("conform.util")
		local uv = vim.uv or vim.loop

		-- Cacheamos los patrones de archivos raíz para evitar recrear tablas en cada guardado
		local eslint_files = {
			".eslintrc",
			".eslintrc.cjs",
			".eslintrc.js",
			".eslintrc.json",
			".eslintrc.yaml",
			".eslintrc.yml",
			"eslint.config.js",
			"eslint.config.cjs",
			"eslint.config.mjs",
			"eslint.config.ts",
		}

		local prettier_files = {
			".prettierrc",
			".prettierrc.json",
			".prettierrc.js",
			".prettierrc.cjs",
			".prettierrc.yaml",
			".prettierrc.yml",
			".prettierrc.toml",
			"prettier.config.js",
			"prettier.config.cjs",
			"prettier.config.mjs",
			"prettier.config.ts",
		}

		-- Evita correr eslint/prettier donde no corresponda
		local function has_eslint_root(ctx)
			return util.root_file(eslint_files)(ctx) ~= nil
		end

		local function has_prettier_root(ctx)
			return util.root_file(prettier_files)(ctx) ~= nil
		end

		-- Config de formatters
		conform.setup({
			notify_on_error = false,
			format_on_save = false, -- Controlado manualmente abajo mediante autocmd secuencial
			default_format_opts = {
				lsp_format = "fallback",
				timeout_ms = 1000,
			},
			formatters_by_ft = {
				-- JS/TS: Corre eslint_d secuencialmente, y luego elige entre prettierd O prettier (el primero que esté disponible)
				javascript = { "eslint_d", { "prettierd", "prettier" } },
				javascriptreact = { "eslint_d", { "prettierd", "prettier" } },
				typescript = { "eslint_d", { "prettierd", "prettier" } },
				typescriptreact = { "eslint_d", { "prettierd", "prettier" } },
				jsx = { "eslint_d", { "prettierd", "prettier" } },
				tsx = { "eslint_d", { "prettierd", "prettier" } },
				vue = { "eslint_d", { "prettierd", "prettier" } },
				svelte = { "eslint_d", { "prettierd", "prettier" } },
				astro = { "eslint_d", { "prettierd", "prettier" } },

				lua = { "stylua" },
				python = { "isort", "black" },
				sh = { "shfmt" },
				json = { { "prettierd", "prettier" } },
				yaml = { { "prettierd", "prettier" } },
				markdown = { { "prettierd", "prettier" } },
				css = { { "prettierd", "prettier" } },
				html = { { "prettierd", "prettier" } },
				toml = { "taplo" },
				nix = { "alejandra" },
				go = { "gofumpt", "goimports-reviser" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				rust = { "rustfmt" },

				-- fallback general
				["_"] = { "trim_whitespace", "trim_newlines" },
			},

			-- Ajustes y condiciones específicas por formatter
			formatters = {
				eslint_d = {
					condition = has_eslint_root,
					cwd = util.root_file({ "package.json", "eslint.config.js" }),
					require_cwd = true,
				},
				prettierd = {
					condition = has_prettier_root,
					cwd = util.root_file({ "package.json" }),
					require_cwd = false,
				},
				prettier = {
					condition = has_prettier_root,
					cwd = util.root_file({ "package.json" }),
					require_cwd = false,
				},
				ruff_format = {
					cwd = util.root_file({ "pyproject.toml", "ruff.toml" }),
				},
				black = {
					cwd = util.root_file({ "pyproject.toml", "requirements.txt" }),
				},
				isort = {
					cwd = util.root_file({ "pyproject.toml", "requirements.txt" }),
				},
				shfmt = {
					prepend_args = { "-i", "2", "-ci" },
				},
			},
		})

		---------------------------------------------------------------------
		-- Format-on-save con límites y toggle
		---------------------------------------------------------------------
		local format_enabled = true
		local MAX_SIZE = 200 * 1024 -- 200 KB

		local function safe_format(bufnr)
			local name = vim.api.nvim_buf_get_name(bufnr)
			if name == "" then
				return
			end

			-- API moderna de Neovim
			local ok, st = pcall(uv.fs_stat, name)
			if ok and st and st.size and st.size > MAX_SIZE then
				return
			end

			conform.format({
				bufnr = bufnr,
				lsp_fallback = true,
				quiet = true,
				timeout_ms = 1000,
			})
		end

		-- Autocmd para guardar
		local aug = vim.api.nvim_create_augroup("ConformFormatOnSave", { clear = true })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = aug,
			callback = function(args)
				if not format_enabled then
					return
				end
				safe_format(args.buf)
			end,
		})

		-- Comandos útiles
		vim.api.nvim_create_user_command("Format", function()
			safe_format(vim.api.nvim_get_current_buf())
		end, {})

		vim.api.nvim_create_user_command("FormatToggle", function()
			format_enabled = not format_enabled
			vim.notify("Format on Save: " .. (format_enabled and "ON" or "OFF"), vim.log.levels.INFO)
		end, {})
	end,
}

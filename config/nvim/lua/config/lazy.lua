-- Bootstrap lazy.nvim ---------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Usamos vim.uv en lugar del antiguo vim.loop (API moderna de Neovim)
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

-- Setup ------------------------------------------------------------------------
require("lazy").setup({
	spec = {
		-- Importa de forma automática todo lo que esté en lua/plugins/
		{ import = "plugins" },
	},
	defaults = {
		lazy = true, -- Excelente: los plugins no se cargan a menos que se soliciten
		version = false, -- Usa las ramas principales de Git en lugar de tags (más actualizado)
	},
	install = {
		colorscheme = { "catppuccin", "habamax" }, -- Habamax como fallback nativo seguro
	},
	checker = {
		enabled = true, -- Busca actualizaciones en segundo plano
		notify = false, -- Apaga el molesto aviso flotante cada vez que abres Neovim
	},
	performance = {
		rtp = {
			-- Plugins integrados desactivados para arañar unos milisegundos extra en el arranque
			disabled_plugins = {
				"gzip",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
				"matchit",
				"matchparen",
			},
		},
	},
})

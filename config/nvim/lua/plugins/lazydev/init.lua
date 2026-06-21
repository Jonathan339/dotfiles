local M = {
	{
		"folke/lazydev.nvim",
		ft = "lua", -- solo se carga en archivos de tipo lua
		opts = {
			library = {
				-- Carga los tipos de la API de Neovim
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
}

return M

return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		lazy = true,

		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
		},

		-- keys = {
		-- 	{
		-- 		"<leader>e",
		-- 		"<cmd>Neotree toggle<cr>",
		-- 		desc = "Explorer",
		-- 	},
		-- },

		opts = {
			filesystem = {
				filtered_items = {
					hide_dotfiles = true,
					hide_gitignored = false,
				},
			},

			-- window = {
			-- 	width = 35,
			-- },
		},
	},
}

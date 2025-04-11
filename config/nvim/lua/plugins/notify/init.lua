local M = { "rcarriga/nvim-notify", event = "VeryLazy" }
M.opts = {
	background_colour = "#000000",
	-- level = vim.log.levels.WARN, -- help vim.log.levels
	render = "minimal",
	stages = "static",
	--timeout = 3000,
	icons = require("utils.icons").icons,
}

M.config = function(_, opts)
	require("notify").setup(opts)
	vim.notify = require("notify")
end
return M

return {
	{
		"hyperstown/nvim-live-server",
		cmd = {
			"LiveServerStart",
			"LiveServerStop",
			"LiveServerToggle",
		},
		opts = {
			host = "127.0.0.1",
			port = 5550,
			bind_attempts = 3,
			ignore_files = { "*.env" },
			ignore_dotfiles = true,
			open_browser = true,
		},
	},
}

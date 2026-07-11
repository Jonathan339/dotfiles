local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("DroidSansM Nerd Font")
config.font_size = 12.0

config.window_background_opacity = 0.9
config.window_padding = { left = 2, right = 2, top = 2, bottom = 2 }

config.colors = {
	foreground = "#ffffff",
	background = "#252525",
	cursor_bg = "#ffffff",
	cursor_fg = "#252525",
	cursor_border = "#ffffff",
	selection_fg = "#ffffff",
	selection_bg = "#170830",
	scrollbar_thumb = "#583e53",
	split = "#8f45e3",
	ansi = {
		"#130728",
		"#8f45e3",
		"#8f59aa",
		"#c47be8",
		"#8f45e3",
		"#f485ed",
		"#8f45e3",
		"#fab1ed",
	},
	brights = {
		"#583e53",
		"#ac53ff",
		"#ac6bcc",
		"#e18dff",
		"#b356ff",
		"#ffa6ff",
		"#ac53ff",
		"#ffbaf9",
	},
	tab_bar = {
		background = "#130728",
		active_tab = {
			bg_color = "#8f45e3",
			fg_color = "#ffffff",
		},
		inactive_tab = {
			bg_color = "#583e53",
			fg_color = "#fab1ed",
		},
		inactive_tab_hover = {
			bg_color = "#8f45e3",
			fg_color = "#ffffff",
		},
		new_tab = {
			bg_color = "#130728",
			fg_color = "#fab1ed",
		},
		new_tab_hover = {
			bg_color = "#8f45e3",
			fg_color = "#ffffff",
		},
	},
}

config.default_cursor_style = "SteadyBar"
config.cursor_blink_rate = 0

config.hide_mouse_cursor_when_typing = true

config.default_domain = "unix"
config.default_prog = { "zsh" }

config.keys = {
	{
		key = "n",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" },
	},
	{
		key = "LeftArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Prev"),
	},
	{
		key = "RightArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Next"),
	},
	{
		key = "t",
		mods = "CTRL",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "q",
		mods = "CTRL",
		action = wezterm.action.CloseCurrentTab { confirm = true },
	},
	{
		key = "RightArrow",
		mods = "CTRL",
		action = wezterm.action.ActivateTabRelative(1),
	},
	{
		key = "Tab",
		mods = "CTRL",
		action = wezterm.action.ActivateTabRelative(1),
	},
	{
		key = "LeftArrow",
		mods = "CTRL",
		action = wezterm.action.ActivateTabRelative(-1),
	},
	{
		key = "Tab",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateTabRelative(-1),
	},
	{
		key = "UpArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.MoveTabRelative(-1),
	},
	{
		key = "DownArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.MoveTabRelative(1),
	},
	{
		key = "Enter",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SpawnWindow,
	},
	{
		key = "s",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "l",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ClearScrollback("ScrollbackOnly"),
	},
	{
		key = "F5",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ReloadConfiguration,
	},
}

config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.show_tab_index_in_tab_bar = true

config.check_for_updates = false

return config

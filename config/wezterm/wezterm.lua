local wezterm = require("wezterm")
local config = {}

-- ======================================================
-- TERMINAL (COMPATIBLE)
-- ======================================================
config.term = "xterm-256color"
config.enable_csi_u_key_encoding = true
config.audible_bell = "Disabled"

-- ======================================================
-- GRID EXACTO
-- ======================================================
config.initial_cols = 145
config.initial_rows = 44
config.use_resize_increments = true
config.adjust_window_size_when_changing_font_size = true

-- ======================================================
-- VENTANA
-- ======================================================
config.window_decorations = "TITLE"
config.window_background_opacity = 0.92
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
	top = 0,
	right = 0,
	left = 0,
	bottom = 0,
}

config.enable_tab_bar = false
config.enable_scroll_bar = false

config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

-- ======================================================
-- CURSOR
-- ======================================================
config.default_cursor_style = "SteadyBlock"
config.cursor_blink_rate = 0

-- ======================================================
-- RENDIMIENTO
-- ======================================================
config.scrollback_lines = 10000
config.max_fps = 144

-- ======================================================
-- FUENTE
-- ======================================================
config.font = wezterm.font({
	family = "JetBrains Mono",
	weight = "Regular",
})
config.font_size = 12.5
config.line_height = 1.0
config.cell_width = 1.0

-- ======================================================
-- TEMA
-- ======================================================
config.colors = {
	foreground = "#e4e4f0",
	background = "#07090f",

	cursor_bg = "#8b5cf6",
	cursor_fg = "#07090f",
	cursor_border = "#8b5cf6",

	selection_fg = "#ffffff",
	selection_bg = "#2a1f45",

	ansi = {
		"#11131a",
		"#6d28d9",
		"#5b21b6",
		"#7c3aed",
		"#312e81",
		"#9333ea",
		"#4c1d95",
		"#cbd5e1",
	},

	brights = {
		"#1f2937",
		"#8b5cf6",
		"#7c3aed",
		"#a78bfa",
		"#4338ca",
		"#c084fc",
		"#6366f1",
		"#ffffff",
	},
}

config.automatically_reload_config = true

return config

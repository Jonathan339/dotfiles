local wezterm = require("wezterm")
local config = {}

-- ======================================================
-- TERMINAL
-- ======================================================
config.term = "xterm-256color"
config.enable_csi_u_key_encoding = true
config.audible_bell = "Disabled"

-- ======================================================
-- GRID EXACTO
-- ======================================================
config.window_startup_state = "Normal"
config.initial_cols = 129
config.initial_rows = 41
config.use_resize_increments = false -- Evita maximización forzada
config.adjust_window_size_when_changing_font_size = false

-- ======================================================
-- VENTANA
-- ======================================================
config.window_decorations = "TITLE" -- Solo barra de título
config.window_background_opacity = 0.92
config.enable_tab_bar = false -- Sin barra de pestañas
config.enable_scroll_bar = false -- Sin barra de desplazamiento

config.window_padding = {
	top = 0,
	right = 0,
	left = 0,
	bottom = 0,
}

config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

-- ======================================================
-- CURSOR
-- ======================================================
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 0 -- Sin parpadeo

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
config.font_size = 12.2 -- Ajustado para permitir más columnas
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

-- ======================================================
-- TECLAS PERSONALIZADAS
-- ======================================================
config.keys = {
	-- Soluciona backspace enviando BS en lugar de DEL
	{ key = "Backspace", mods = "NONE", action = wezterm.action.SendString("\x08") },
}

-- ======================================================
-- GENERAL
-- ======================================================
config.automatically_reload_config = true

return config

---@diagnostic disable: undefined-global
local M = {}

M.setup = function()
	-- Cargador nativo (en versiones modernas ya viene activo por defecto, pero no viene mal asegurar)
	if vim.loader and vim.loader.enable then
		vim.loader.enable()
	end

	-- Mapeo de Líder
	vim.g.mapleader = ","
	vim.g.maplocalleader = ","

	-- Desactiva netrw para acelerar el arranque (ideal si usás Neo-tree u Oil)
	vim.g.loaded_netrw = 1
	vim.g.loaded_netrwPlugin = 1

	-- Codificación
	vim.scriptencoding = "utf-8"
	vim.opt.encoding = "utf-8"
	vim.opt.fileencoding = "utf-8"

	-- Clipboard (Portapapeles del sistema)
	vim.opt.clipboard = "unnamedplus"

	-- Números en la barra lateral
	vim.opt.number = true
	vim.opt.relativenumber = true

	-- UI / Estética visual
	vim.opt.title = true
	vim.opt.termguicolors = true
	vim.opt.cmdheight = 0     -- Oculta la barra de comandos inferior (ideal para noice.nvim)
	vim.opt.laststatus = 3    -- Statusline global única abajo de todo (ideal para lualine)
	vim.opt.showmode = false  -- No duplica el modo (-- INSERT --) porque ya lo muestra la statusline
	vim.opt.signcolumn = "yes" -- Fija la columna de signos para evitar saltos visuales de diagnósticos

	-- Búsqueda inteligente
	vim.opt.hlsearch = false
	vim.opt.incsearch = true
	vim.opt.ignorecase = true
	vim.opt.smartcase = true

	-- Interacción y Comportamiento del Editor
	vim.opt.mouse = "" -- Sin mouse para forzar puro teclado
	vim.opt.timeoutlen = 400
	vim.opt.updatetime = 200
	vim.opt.scrolloff = 10
	vim.opt.splitbelow = true
	vim.opt.splitright = true
	vim.opt.splitkeep = "cursor" -- Mantiene el cursor estable al scrollear o partir pantallas

	-- Edición / Indentación (2 espacios por defecto)
	vim.opt.autoindent = true
	vim.opt.smartindent = true
	vim.opt.expandtab = true
	vim.opt.shiftwidth = 2
	vim.opt.tabstop = 2
	vim.opt.smarttab = true
	vim.opt.breakindent = true
	vim.opt.wrap = false
	vim.opt.backspace = { "start", "eol", "indent" }

	-- Menú de completado automático (Optimizado para nvim-cmp)
	vim.opt.completeopt = { "menu", "menuone", "noselect" }
	vim.opt.pumheight = 12 -- Altura máxima del menú flotante de autocompletado

	-- Comandos interactivos
	vim.opt.showcmd = true
	vim.opt.inccommand = "split" -- Muestra previsualizaciones de comandos (ej: sustituciones %s) en tiempo real

	-- Ocultamiento de sintaxis (Conceal)
	vim.o.conceallevel = 1

	-- Paths / Ignorar archivos en búsquedas globales e indexado nativo
	vim.opt.path:append({ "**" })
	vim.opt.wildignore:append({
		"*/node_modules/*",
		"*/dist/*",
		"*/build/*",
		"*.o",
		"*.a",
		"*.class",
		"*.out",
		".git/*",
	})

	-- Historial persistente (Guarda los undos incluso al cerrar Neovim)
	vim.opt.undofile = true

	-- Reglas de formateo en comentarios
	vim.opt.formatoptions:append({ "r" }) -- Continúa el formato de comentarios al presionar Enter

	-- Configuración de Undercurl (subrayado ondulado para errores si tu terminal lo banca)
	pcall(function()
		vim.cmd([[let &t_Cs = "\e[4:3m"]])
		vim.cmd([[let &t_Ce = "\e[4:0m"]])
	end)
end

-- Ejecutamos la configuración inmediatamente al requerir el archivo
M.setup()

return M

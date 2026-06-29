local map = require("utils").map

-- ======================================================
-- GENERAL
-- ======================================================

map("n", "<C-a>", "ggVG", {
	desc = "Seleccionar todo",
})

map("i", ",,", "<ESC>", {
	desc = "Salir del modo insertar",
})

map("n", "<Leader>w", ":w!<CR>", {
	desc = "Guardar archivo actual",
})

map("n", "<Leader>q", ":x!<CR>", {
	desc = "Salir del editor",
})

map("n", "<Leader><Leader>", "<C-^>", {
	desc = "Alternar entre archivos",
})

map("n", "<Leader>r", ":%s/", {
	desc = "Buscar y reemplazar",
})

-- ======================================================
-- NEOTREE
-- ======================================================

map("n", "<Leader>n", ":Neotree float<CR>", {
	desc = "Abrir Neotree",
})

-- ======================================================
-- OIL
-- ======================================================

map("n", "-", "<CMD>Oil --float<CR>", {
	desc = "Abrir directorio principal",
})

-- ======================================================
-- TERMINAL
-- ======================================================

map("n", "<Leader>t", ":ToggleTerm<CR>", {
	desc = "Abrir terminal",
})

-- ======================================================
-- BUFFERS
-- ======================================================

map("n", "<A-Right>", ":bnext<CR>", {
	desc = "Siguiente buffer",
})

map("n", "<A-Left>", ":bprevious<CR>", {
	desc = "Buffer anterior",
})

map("n", "<Leader>c", ":bp<bar>sp<bar>bn<bar>bd<CR>", {
	desc = "Cerrar buffer",
})

-- ======================================================
-- TELESCOPE
-- ======================================================

map("n", "<C-s>", ":Telescope current_buffer_fuzzy_find<CR>", {
	desc = "Buscar en buffer actual",
})

map("n", "<Leader>f", function()
	require("telescope.builtin").find_files()
end, {
	desc = "Buscar archivos",
})

map("n", "<Leader>b", function()
	require("telescope.builtin").buffers()
end, {
	desc = "Buscar buffers",
})

map("n", "<Leader>h", function()
	require("telescope.builtin").help_tags()
end, {
	desc = "Ayuda de Telescope",
})

map("n", "<Leader>l", function()
	local ok, lga = pcall(function()
		return require("telescope").extensions.live_grep_args
	end)
	if ok and lga then
		lga.live_grep_args()
	else
		require("telescope.builtin").live_grep()
	end
end, {
	desc = "Buscar palabras",
})

-- ======================================================
-- RUN CODE
-- ======================================================

map("n", "<Leader>m", ":RunCode<CR>", {
	desc = "Ejecutar archivo",
})

-- ======================================================
-- MOVIMIENTO DE LÍNEAS
-- ======================================================

map("n", "<C-Up>", ":move -2<CR>==", {
	desc = "Mover línea arriba",
})

map("n", "<C-Down>", ":move +1<CR>==", {
	desc = "Mover línea abajo",
})

map("i", "<C-Up>", "<Esc>:move -2<CR>gi", {
	desc = "Mover línea arriba",
})

map("i", "<C-Down>", "<Esc>:move +1<CR>gi", {
	desc = "Mover línea abajo",
})

map("v", "<C-Up>", ":move '<-2<CR>gv=gv", {
	desc = "Mover selección arriba",
})

map("v", "<C-Down>", ":move '>+1<CR>gv=gv", {
	desc = "Mover selección abajo",
})

-- ======================================================
-- SMART SPLITS
-- ======================================================

map("n", "<A-h>", function()
	require("smart-splits").resize_left()
end, {
	desc = "Redimensionar izquierda",
})

map("n", "<A-j>", function()
	require("smart-splits").resize_down()
end, {
	desc = "Redimensionar abajo",
})

map("n", "<A-k>", function()
	require("smart-splits").resize_up()
end, {
	desc = "Redimensionar arriba",
})

map("n", "<A-l>", function()
	require("smart-splits").resize_right()
end, {
	desc = "Redimensionar derecha",
})

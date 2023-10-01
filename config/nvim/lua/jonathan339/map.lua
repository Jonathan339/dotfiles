-- Cargar el módulo Vim global
local g = vim.g
-- Definir los líderes de los mapas de teclas
g.mapleader = ','
g.maplocalleader = ','
-- Salir de modo insertar
vim.api.nvim_set_keymap('i', ',,', '<ESC>', {noremap = true})
-- Guardar el archivo actual
vim.api.nvim_set_keymap('i', '<Leader>w', '<ESC>:w!<cr>', {noremap = true})
-- Salir del editor
vim.api.nvim_set_keymap('n', '<Leader>q', ':q!<cr>', {noremap = true})
-- Buscar archivos con Files
vim.api.nvim_set_keymap('n', '<Leader>f', ':Telescope find_files<cr>', {noremap = true})
-- Buscar buffers con Buffers
vim.api.nvim_set_keymap('n', '<Leader>b', ':Telescope buffers<cr>', {noremap = true})
-- ayuda con Telescope
vim.api.nvim_set_keymap('n', '<Leader>h', ':Telescope help_tags<cr>', {noremap = true})
-- Buscar palabras con Telescope
vim.api.nvim_set_keymap('n', '<Leader>l', ':Telescope live_grep<cr>', {noremap = true})
-- Abrir buffers con Buffers
vim.api.nvim_set_keymap('n', '<Leader>b', ':Buffers<cr>', {noremap = true})
-- terminal con ToggleTerm
vim.api.nvim_set_keymap('n', '<Leader>t', ':ToggleTerm direction=float<cr>', {noremap = true})
vim.api.nvim_set_keymap('n', '<Leader>c', ':NERDTreeToggle<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<Leader>C', ':NERDTreeClose<CR>', {noremap = true})
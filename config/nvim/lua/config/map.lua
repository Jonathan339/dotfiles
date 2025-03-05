local map = require('utils').map

-- Salir del modo insertar
map('i', ',,', '<ESC>', { desc = 'Salir del modo insertar' })

-- Neotree
map('n', '<Leader>n', ':Neotree float<CR>', { desc = 'Neotree' })

-- Guardar el archivo actual
map('n', '<Leader>w', ':w!<CR>', { desc = 'Guardar el archivo actual' })

-- Netrw
map('n', '<Leader>e', ':Ex<CR>', { desc = 'Salir del editor' })

-- Navegar buffers
map('n', '<A-Right>', ':bnext<CR>', { desc = 'Saltar al siguiente buffer' })
map('n', '<A-Left>', ':bprevious<CR>', { desc = 'Saltar al buffer anterior' })

-- terminal
map('n', '<Leader>t', ':ToggleTerm<CR>', { desc = 'Terminal' })
-- Seleccionar todo
map('n', '<C-a>', 'ggVG', { desc = 'Seleccionar todo' })

-- Buscar en el buffer actual
map('n', '<C-s>', ':Telescope current_buffer_fuzzy_find<CR>', { desc = 'Buscar en el buffer actual' })

vim.keymap.set('n', '-', '<CMD>Oil --float<CR>', { desc = 'Open parent directory' })
-- Salir del editor
map('n', '<Leader>q', ':x!<CR>', { desc = 'Salir del editor' })

-- Ejecutar el archivo actual
map('n', '<Leader>m', ':RunCode<CR>', { desc = 'Ejecutar el archivo actual' })

-- Buscar archivos con Telescope
map('n', '<Leader>f', ':Telescope find_files<CR>', { desc = 'Buscar archivos con Telescope' })

-- Buscar buffers con Telescope
map('n', '<Leader>b', function()
  local builtin = require('telescope.builtin')
  builtin.buffers()
end, { desc = 'Buscar buffers con Telescope' })

-- Oil

--map('n', '<Leader>o',"<CMD>Oil<CR>", { desc = "Open parent directory" }))

-- Ayuda con Telescope
map('n', '<Leader>h', function()
  local builtin = require('telescope.builtin')
  builtin.help_tags()
end, { desc = 'Ayuda con Telescope' })

-- Buscar palabras con Telescope
map('n', '<Leader>l', ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
  { desc = 'Buscar palabras con Telescope' })

-- Mover líneas hacia arriba o abajo
map('n', '<A-Up>', ':m .-2<CR>==', { desc = 'Mover línea hacia arriba' })
map('n', '<A-Down>', ':m .+1<CR>==', { desc = 'Mover línea hacia abajo' })
map('i', '<A-Up>', '<Esc>:m .-2<CR>==gi', { desc = 'Mover línea hacia arriba' })
map('i', '<A-Down>', '<Esc>:m .+1<CR>==gi', { desc = 'Mover línea hacia abajo' })
map('v', '<A-Up>', ":m '<-2<CR>gv=gv", { desc = 'Mover selección hacia arriba' })
map('v', '<A-Down>', ":m '>+1<CR>gv=gv", { desc = 'Mover selección hacia abajo' })

-- Alternar entre archivos abiertos
map('n', '<Leader><Leader>', '<C-^>', { desc = 'Alternar entre archivos abiertos' })

-- Cerrar buffer sin cerrar ventana
map('n', '<Leader>c', ':bp<bar>sp<bar>bn<bar>bd<CR>', { desc = 'Cerrar buffer sin cerrar ventana' })

-- Buscar y reemplazar en el archivo actual
map('n', '<Leader>r', ':%s/', { desc = 'Buscar y reemplazar en el archivo actual' })

-- Asignar combinaciones de teclas para redimensionar ventanas con smart-splits
map('n', '<A-h>', require('smart-splits').resize_left, { desc = 'Redimensionar ventana a la izquierda' })
map('n', '<A-j>', require('smart-splits').resize_down, { desc = 'Redimensionar ventana hacia abajo' })
map('n', '<A-k>', require('smart-splits').resize_up, { desc = 'Redimensionar ventana hacia arriba' })
map('n', '<A-l>', require('smart-splits').resize_right, { desc = 'Redimensionar ventana a la derecha' })

-- Asignar combinaciones de teclas para mover el cursor entre ventanas con smart-splits
map('n', '<C-h>', require('smart-splits').move_cursor_left, { desc = 'Mover cursor a la ventana izquierda' })
map('n', '<C-j>', require('smart-splits').move_cursor_down, { desc = 'Mover cursor a la ventana inferior' })
map('n', '<C-k>', require('smart-splits').move_cursor_up, { desc = 'Mover cursor a la ventana superior' })
map('n', '<C-l>', require('smart-splits').move_cursor_right, { desc = 'Mover cursor a la ventana derecha' })

local map = require('utils.init').map

local ok_telescope, telescope_builtin = pcall(require, 'telescope.builtin')
local ok_smart_splits, smart_splits = pcall(require, 'smart-splits')

if not ok_smart_splits then
  smart_splits = {
    resize_left = function() vim.cmd('vertical resize -3') end,
    resize_down = function() vim.cmd('resize -3') end,
    resize_up = function() vim.cmd('resize +3') end,
    resize_right = function() vim.cmd('vertical resize +3') end,
    move_cursor_left = function() vim.cmd('wincmd h') end,
    move_cursor_down = function() vim.cmd('wincmd j') end,
    move_cursor_up = function() vim.cmd('wincmd k') end,
    move_cursor_right = function() vim.cmd('wincmd l') end,
  }
end

-- Seleccionar todo
map('n', '<C-a>', 'ggVG', { desc = 'Seleccionar todo' })
-- Salir del modo insertar
map('i', ',,', '<ESC>', { desc = 'Salir del modo insertar' })

-- Neotree
map('n', '<Leader>n', ':Neotree float<CR>', { desc = 'Neotree' })

-- Terminal
map('n', '<Leader>t', ':ToggleTerm<CR>', { desc = 'Terminal' })

-- Guardar el archivo actual
map('n', '<Leader>w', ':w!<CR>', { desc = 'Guardar el archivo actual' })

-- Navegar buffers
map('n', '<A-Right>', ':bnext<CR>', { desc = 'Siguiente buffer' })
map('n', '<A-Left>', ':bprevious<CR>', { desc = 'Buffer anterior' })

-- Buscar
map('n', '<C-s>', ':Telescope current_buffer_fuzzy_find<CR>', { desc = 'Buscar en el buffer actual' })
map('n', '<Leader>f', ':Telescope find_files<CR>', { desc = 'Buscar archivos' })
map('n', '<Leader>b', function()
  if ok_telescope then
    telescope_builtin.buffers()
  end
end, { desc = 'Buscar buffers' })
map('n', '<Leader>h', function()
  if ok_telescope then
    telescope_builtin.help_tags()
  end
end, { desc = 'Ayuda con Telescope' })
map('n', '<Leader>l', ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", { desc = 'Buscar palabras' })

-- Ejecutar archivo y salir del editor
map('n', '<Leader>m', ':RunCode<CR>', { desc = 'Ejecutar archivo' })
map('n', '<Leader>q', ':x!<CR>', { desc = 'Salir del editor' })

-- Alternar entre archivos y cerrar buffers
map('n', '<Leader><Leader>', '<C-^>', { desc = 'Alternar entre archivos' })
map('n', '<Leader>c', ':bp<bar>sp<bar>bn<bar>bd<CR>', { desc = 'Cerrar buffer' })

-- Buscar y reemplazar
map('n', '<Leader>r', ':%s/', { desc = 'Buscar y reemplazar' })

-- Mover líneas y selección
-- Mover líneas en modo normal
map('n', '<C-Up>', ':move -2<CR>==', { desc = 'Mover línea arriba' })
map('n', '<C-Down>', ':move +1<CR>==', { desc = 'Mover línea abajo' })

-- Mover líneas en modo inserción
map('i', '<C-Up>', '<Esc>:move -2<CR>gi', { desc = 'Mover línea arriba' })
map('i', '<C-Down>', '<Esc>:move +1<CR>gi', { desc = 'Mover línea abajo' })

-- Mover selección en modo visual
map('v', '<C-Up>', ":move '<-2<CR>gv=gv", { desc = 'Mover selección arriba' })
map('v', '<C-Down>', ":move '>+1<CR>gv=gv", { desc = 'Mover selección abajo' })

-- Redimensionar y mover entre ventanas con smart-splits
map('n', '<A-h>', smart_splits.resize_left, { desc = 'Redimensionar izquierda' })
map('n', '<A-j>', smart_splits.resize_down, { desc = 'Redimensionar abajo' })
map('n', '<A-k>', smart_splits.resize_up, { desc = 'Redimensionar arriba' })
map('n', '<A-l>', smart_splits.resize_right, { desc = 'Redimensionar derecha' })

map('n', '<C-h>', smart_splits.move_cursor_left, { desc = 'Mover cursor izquierda' })
map('n', '<C-j>', smart_splits.move_cursor_down, { desc = 'Mover cursor abajo' })
map('n', '<C-k>', smart_splits.move_cursor_up, { desc = 'Mover cursor arriba' })
map('n', '<C-l>', smart_splits.move_cursor_right, { desc = 'Mover cursor derecha' })

-- Mapeo para abrir el directorio principal
map('n', '-', '<CMD>Oil --float<CR>', { desc = 'Abrir directorio principal' })

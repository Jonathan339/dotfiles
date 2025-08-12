-- lua/config/options.lua
---@diagnostic disable: undefined-global

-- Cargador nativo (arranque más rápido)
if vim.loader and vim.loader.enable then
  vim.loader.enable()
end

-- Leader
vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- (Si usás Oil/Neo-tree) desactiva netrw para acelerar
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Codificación
vim.scriptencoding = 'utf-8'
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'

-- Clipboard
vim.opt.clipboard = 'unnamedplus'

-- Números
vim.opt.number = true
vim.opt.relativenumber = true

-- UI / statusline
vim.opt.title = true
vim.opt.termguicolors = true
vim.opt.cmdheight = 0      -- ideal con noice.nvim
vim.opt.laststatus = 3     -- 🔥 globalstatus para lualine
vim.opt.showmode = false   -- lualine muestra el modo
vim.opt.signcolumn = 'yes' -- evita “salto” al aparecer diagnósticos

-- Búsqueda
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Interacción
vim.opt.mouse = '' -- vacío = sin mouse (déjalo así si te gusta)
vim.opt.timeoutlen = 400
vim.opt.updatetime = 200
vim.opt.scrolloff = 10
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.splitkeep = 'cursor'

-- Edición / indentación
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smarttab = true
vim.opt.breakindent = true
vim.opt.wrap = false
vim.opt.backspace = { 'start', 'eol', 'indent' }

-- Completado (mejor para nvim-cmp)
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.pumheight = 12

-- Comandos
vim.opt.showcmd = true
vim.opt.inccommand = 'split'

-- Paths / ignore
vim.opt.path:append({ '**' })
vim.opt.wildignore:append({
  '*/node_modules/*',
  '*/dist/*',
  '*/build/*',
  '*.o',
  '*.a',
  '*.class',
  '*.out',
  '.git/*',
})

-- Undo persistente (cómodo al cerrar/abrir)
vim.opt.undofile = true

-- Formatoptions (mantengo tu preferencia y agrego bajo riesgo)
vim.opt.formatoptions:append({ 'r' }) -- * en comentarios al hacer Enter

-- Undercurl (si tu terminal lo soporta)
pcall(vim.cmd, [[let &t_Cs = "\e[4:3m"]])
pcall(vim.cmd, [[let &t_Ce = "\e[4:0m"]])

-- Nota: no tocamos swap/backup; tus autocmds ya manejan casos grandes.

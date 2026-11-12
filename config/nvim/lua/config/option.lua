-- lua/config/option.lua
---@diagnostic disable: undefined-global

-- Cargador nativo (arranque más rápido)
if vim.loader then
  vim.loader.enable()
end

-- Providers que no usamos: evitan el chequeo/arranque de python3/perl/ruby/node
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

-- PATH común: Neovim puede lanzarse desde el escritorio (KDE) sin el PATH
-- del shell. Agregamos una sola vez cada toolchain que exista.
local function prepend_path(dir)
  if dir == '' or vim.fn.isdirectory(dir) ~= 1 then
    return
  end
  if not (vim.env.PATH or ''):find(dir, 1, true) then
    vim.env.PATH = dir .. ':' .. (vim.env.PATH or '')
  end
end

-- Mason debe ir primero: el LSP arranca en BufReadPre, antes de que Mason
-- cargue (VeryLazy) y agregue su bin al PATH.
prepend_path(vim.fn.stdpath('data') .. '/mason/bin')
-- Node (fnm): bashls/tailwindcss/vtsls son scripts "#!/usr/bin/env node".
prepend_path(vim.fn.expand('~/.local/share/fnm/aliases/default/bin'))
-- Rust (rustup): rust-analyzer y rustfmt.
prepend_path(vim.fn.expand('~/.cargo/bin'))
-- Bun: ejecuta TS (<leader>m) y algunos binarios de proyectos.
prepend_path(vim.fn.expand('~/.bun/bin'))

-- Leader
vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- (Si usás Oil/Neo-tree) desactiva netrw para acelerar
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Codificación
vim.opt.fileencoding = 'utf-8'

-- Clipboard
vim.opt.clipboard = 'unnamedplus'

-- Números
vim.opt.number = true
vim.opt.relativenumber = true

-- UI / statusline
vim.opt.title = true
vim.opt.termguicolors = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 3 -- 🔥 globalstatus para lualine
vim.opt.showmode = false -- lualine muestra el modo
vim.opt.signcolumn = 'yes' -- evita “salto” al aparecer diagnósticos

-- Búsqueda
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.inccommand = 'split' -- preview de :s en vivo

-- Interacción
vim.opt.mouse = 'a' -- 'a' = ratón completo (click, scroll, drag) si el terminal lo soporta
vim.opt.timeoutlen = 400
vim.opt.updatetime = 200
vim.opt.scrolloff = 10
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.splitkeep = 'cursor'

-- Edición / indentación
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.breakindent = true
vim.opt.wrap = false

-- Completado (mejor para nvim-cmp)
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.pumheight = 12

-- Conceal: markdown/quarto lo suben a 2 en config/autocmd.lua
vim.opt.conceallevel = 0

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
pcall(function()
  vim.o.t_Cs = '\027[4:3m'
end)
pcall(function()
  vim.o.t_Ce = '\027[4:0m'
end)

-- Nota: no tocamos swap/backup; tus autocmds ya manejan casos grandes.

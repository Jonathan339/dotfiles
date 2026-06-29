-- lua/config/options.lua
---@diagnostic disable: undefined-global

-- Cargador nativo (arranque más rápido)
if vim.loader then
  vim.loader.enable()
end

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
vim.opt.cmdheight = 0 -- ideal con noice.nvim
vim.opt.laststatus = 3 -- 🔥 globalstatus para lualine
vim.opt.showmode = false -- lualine muestra el modo
vim.opt.signcolumn = 'yes' -- evita “salto” al aparecer diagnósticos

-- Notificaciones (noice.nvim)
if vim.fn.exists("*noice") == 1 then
  vim.opt.cmdheight = 0
  vim.opt.showmode = false
  pcall(function()
    require('noice').setup({
      messages = {
        view = 'mini',
        view_error = 'notify',
        view_warn = 'notify',
        view_search = false,
      },
      notify = { enabled = true },
      cmdline = { view = 'cmdline_popup' },
      views = {
        cmdline_popup = {
          position = { row = '35%', col = '50%' },
          size = { width = 60, height = 'auto' },
          border = { style = 'rounded' },
        },
      },
    })
  end)
end

-- Búsqueda
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
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.breakindent = true
vim.opt.wrap = false

-- Completado (mejor para nvim-cmp)
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.pumheight = 12

--
vim.opt.conceallevel = 1

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
pcall(function() vim.o.t_Cs = '\027[4:3m' end)
pcall(function() vim.o.t_Ce = '\027[4:0m' end)

-- Nota: no tocamos swap/backup; tus autocmds ya manejan casos grandes.
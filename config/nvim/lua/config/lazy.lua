-- vim.g.mapleader = ','
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

-- Verificar si el repositorio de lazy.nvim ya existe
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out,                            'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

-- Agregar el camino a 'runtimepath'
vim.opt.rtp:prepend(lazypath)

-- Configuración de 'lazy.nvim'
require('lazy').setup({
  spec = {
    { import = 'plugins' }, -- Importar plugins desde tu carpeta de configuración
  },
  defaults = {
    lazy = true,     -- Cargar plugins personalizados solo cuando se necesiten
    version = false, -- Usar siempre el último commit de cada plugin
  },
  install = {
    missing = true,                 -- Instalar plugins pendientes de instalar
    colorscheme = { 'catppuccin' }, -- Esquemas de color a instalar
  },
  checker = {
    enabled = true, -- Verificar actualizaciones de plugins periódicamente
    notify = false, -- Desactivar notificaciones de actualizaciones
  },
  performance = {
    rtp = {
      disabled_plugins = {
        'gzip',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
        'matchit',
        'matchparen',
      },
    },
  },
})

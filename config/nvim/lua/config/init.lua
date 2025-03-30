-- Función para cargar módulos de manera segura
local function safe_require(module)
  local ok, err = pcall(require, module)
  if not ok then
    vim.notify('Error loading ' .. module .. '\n\n' .. err, vim.log.levels.ERROR)
  end
end

-- Carga módulos de manera sincrónica
local function load_modules(modules)
  for _, module in ipairs(modules) do
    safe_require(module)
  end
end

-- @returns: true if the string is empty, false otherwise
-- Módulos principales
local main_modules = { 'config.options', 'config.lazy', 'config.map' }
load_modules(main_modules)

-- Módulos secundarios cargados de manera asíncrona
vim.schedule(function()
  local async_modules = {
    'config.autocmd',
    'plugins.lsp.diagnostics',
  }
  load_modules(async_modules)
end)

-- Carga condicional de módulos
if vim.fn.isdirectory(vim.fn.expand('~/.config/nvim/lua/lsp')) == 1 then
  vim.defer_fn(function()
    safe_require('lsp.diagnostics')
  end, 0)
end
vim.cmd.colorscheme('catppuccin-macchiato')

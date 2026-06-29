---@diagnostic disable: undefined-global
-- lua/config/autocmd.lua
local agroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local M = {}

local function augroup(name)
  return agroup(name, { clear = true })
end

autocmd('VimLeave', {
  group = augroup('reset_terminal_background'),
  desc = 'Evitar que quede fondo forzado al salir',
  callback = function()
    pcall(function() vim.o.t_ut = '' end)
    vim.cmd('highlight Normal guibg=NONE ctermbg=NONE')
  end,
})
-----------------------------------------------------------------------
-- Crear directorios automáticamente antes de guardar
-----------------------------------------------------------------------
autocmd('BufWritePre', {
  group = augroup('auto_create_dir'),
  desc = 'Crear directorios faltantes antes de guardar',
  callback = function(ev)
    local file = ev.match or ev.file
    if not file or file:match('^%w%w+://') then
      return
    end -- esquemas tipo netrw
    local dir = vim.fn.fnamemodify(file, ':p:h')
    if dir ~= '' and vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, 'p')
    end
  end,
})

-----------------------------------------------------------------------
-- Wrap + spell en textos
-----------------------------------------------------------------------
autocmd('FileType', {
  group = augroup('text_settings'),
  pattern = { 'gitcommit', 'markdown', 'NeogitCommitMessage' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-----------------------------------------------------------------------
-- Luasnip: limpiar snippets al salir de Insert
-----------------------------------------------------------------------
autocmd('InsertLeave', {
  group = augroup('luasnip_unlink_leave'),
  callback = function()
    local ok, ls = pcall(require, 'luasnip')
    if not ok then
      return
    end
    local buf = vim.api.nvim_get_current_buf()
    if ls.session.current_nodes[buf] and not ls.session.jump_active then
      pcall(ls.unlink_current)
    end
  end,
})

-----------------------------------------------------------------------
-- Auto-reload cuando cambian archivos afuera
-----------------------------------------------------------------------
autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup('checktime'),
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd('checktime')
    end
  end,
})

-----------------------------------------------------------------------
-- Highlights para nvim-cmp (aplicar en ColorScheme/VimEnter)
-----------------------------------------------------------------------
local function set_cmp_highlights()
  vim.schedule(function()
    vim.api.nvim_set_hl(0, 'CmpItemAbbrDeprecated', { bg = 'NONE', strikethrough = true, fg = '#808080' })
    vim.api.nvim_set_hl(0, 'CmpItemAbbrMatch', { bg = 'NONE', fg = '#569CD6' })
    vim.api.nvim_set_hl(0, 'CmpItemAbbrMatchFuzzy', { link = 'CmpItemAbbrMatch' })
    vim.api.nvim_set_hl(0, 'CmpItemKindVariable', { bg = 'NONE', fg = '#9CDCFE' })
    vim.api.nvim_set_hl(0, 'CmpItemKindInterface', { link = 'CmpItemKindVariable' })
    vim.api.nvim_set_hl(0, 'CmpItemKindText', { link = 'CmpItemKindVariable' })
    vim.api.nvim_set_hl(0, 'CmpItemKindFunction', { bg = 'NONE', fg = '#C586C0' })
    vim.api.nvim_set_hl(0, 'CmpItemKindMethod', { link = 'CmpItemKindFunction' })
    vim.api.nvim_set_hl(0, 'CmpItemKindKeyword', { bg = 'NONE', fg = '#D4D4D4' })
    vim.api.nvim_set_hl(0, 'CmpItemKindProperty', { link = 'CmpItemKindKeyword' })
    vim.api.nvim_set_hl(0, 'CmpItemKindUnit', { link = 'CmpItemKindKeyword' })
  end)
end

autocmd({ 'ColorScheme', 'VimEnter' }, {
  group = augroup('cmp_hls'),
  callback = set_cmp_highlights,
})

-----------------------------------------------------------------------
-- Redimensionar splits al cambiar tamaño
-----------------------------------------------------------------------
autocmd('VimResized', {
  group = augroup('resize_splits'),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd('tabdo wincmd =')
    vim.cmd('tabnext ' .. current_tab)
  end,
})

-----------------------------------------------------------------------
-- Resaltado al yank
-----------------------------------------------------------------------
autocmd('TextYankPost', {
  group = augroup('highlight_yank'),
  callback = function()
    pcall(vim.highlight.on_yank, { higroup = 'IncSearch', timeout = 150 })
  end,
})

-----------------------------------------------------------------------
-- Cerrar con 'q' ciertos buffers auxiliares
-----------------------------------------------------------------------
autocmd('FileType', {
  group = augroup('close_with_q'),
  pattern = {
    'PlenaryTestPopup',
    'help',
    'lspinfo',
    'notify',
    'qf',
    'query',
    'spectre_panel',
    'startuptime',
    'tsplayground',
    'neotest-output',
    'checkhealth',
    'neotest-summary',
    'neotest-output-panel',
  },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = ev.buf, silent = true })
  end,
})

-----------------------------------------------------------------------
-- Archivos grandes: ajustar para evitar lag
-----------------------------------------------------------------------
autocmd('BufReadPre', {
  group = augroup('large_file_optimizations'),
  callback = function(ev)
    local file = ev.match or ev.file or vim.api.nvim_buf_get_name(0)
    if not file or file == '' then
      return
    end
    local ok, stat = pcall(vim.uv.fs_stat, file)
    local max_size = 500 * 1024 -- 500 KB (podés bajarlo si querés)
    if ok and stat and stat.size and stat.size > max_size then
      vim.b.large_file = true
      vim.cmd('syntax off')
      vim.opt_local.swapfile = false
      vim.opt_local.undofile = false
      vim.opt_local.foldenable = false
    end
  end,
})

-----------------------------------------------------------------------
-- Volver a la última posición al reabrir el archivo
-----------------------------------------------------------------------
autocmd('BufReadPost', {
  group = augroup('restore_last_cursor'),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, [["]])
    local lcount = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ==========================================
-- Compilar y ejecutar C / C++
-- ==========================================

local function run_c_cpp()
  local file = vim.fn.expand('%:p')
  local ext = vim.fn.expand('%:e')
  local filename = vim.fn.expand('%:t:r')
  local dir = vim.fn.expand('%:p:h')
  local build_dir = dir .. '/build'
  local output = build_dir .. '/' .. filename

  if ext ~= 'c' and ext ~= 'cpp' then
    vim.notify('No es archivo C o C++', vim.log.levels.ERROR)
    return
  end

  -- Guardar archivo
  vim.cmd('write')

  -- Crear carpeta build si no existe
  vim.fn.mkdir(build_dir, 'p')

  -- Borrar ejecutable viejo si existe
  vim.fn.delete(output)

  local compile_cmd

  if ext == 'c' then
    compile_cmd = string.format('gcc -std=c11 -Wall -Wextra -O2 %s -o %s', vim.fn.shellescape(file), vim.fn.shellescape(output))
  else
    compile_cmd = string.format('g++ -std=c++20 -Wall -Wextra -O2 %s -o %s', vim.fn.shellescape(file), vim.fn.shellescape(output))
  end

  -- Compilar
  local compile_result = vim.fn.system(compile_cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify('Error de compilación:\n' .. compile_result, vim.log.levels.ERROR)
    return
  end

  -- Comando a ejecutar dentro de la terminal
  local full_cmd = string.format('cd %s && ./%s; echo; printf "\\nPresiona ENTER para cerrar..."; read; rm -f %s', vim.fn.shellescape(build_dir), filename, vim.fn.shellescape(output))

  -- Ejecutar en Alacritty (forma compatible)
  vim.fn.jobstart({
    'alacritty',
    '-e',
    'bash',
    '-c',
    full_cmd,
  }, { detach = true })
end

M.run_c_cpp = run_c_cpp

return M


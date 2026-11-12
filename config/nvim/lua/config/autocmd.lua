-- lua/config/autocmd.lua

local agroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

---@diagnostic disable: undefined-global

-----------------------------------------------------------------------
-- Utilidad: crear grupos de autocmd sin duplicados
-----------------------------------------------------------------------
local function augroup(name)
  return agroup(name, { clear = true })
end

-----------------------------------------------------------------------
-- Restaurar terminal al salir de Neovim
-----------------------------------------------------------------------
autocmd('VimLeave', {
  group = augroup('reset_terminal_background'),
  desc = 'Evitar que quede fondo forzado al salir',
  callback = function()
    pcall(function()
      vim.o.t_ut = ''
      vim.cmd('highlight Normal guibg=NONE ctermbg=NONE')
    end)
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

    if not file or file == '' or file:match('^%w%w+://') then
      return
    end

    local dir = vim.fn.fnamemodify(file, ':p:h')

    if dir ~= '' and vim.fn.isdirectory(dir) ~= 1 then
      vim.fn.mkdir(dir, 'p')
    end
  end,
})

-----------------------------------------------------------------------
-- Configuración para archivos de texto
-----------------------------------------------------------------------
autocmd('FileType', {
  group = augroup('text_settings'),
  pattern = {
    'gitcommit',
    'markdown',
    'quarto',
    'NeogitCommitMessage',
  },
  callback = function(ev)
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true

    if ev.match == 'markdown' or ev.match == 'quarto' then
      vim.opt_local.conceallevel = 2
      vim.opt_local.colorcolumn = ''
    end
  end,
})

-----------------------------------------------------------------------
-- LuaSnip: limpiar snippets al salir de Insert
-----------------------------------------------------------------------
autocmd('InsertLeave', {
  group = augroup('luasnip_unlink_leave'),
  desc = 'Limpiar snippet activo al salir de Insert',
  callback = function(ev)
    local ok, ls = pcall(require, 'luasnip')

    if not ok then
      return
    end

    local buf = ev.buf

    if ls.session.current_nodes[buf] and not ls.session.jump_active then
      pcall(ls.unlink_current)
    end
  end,
})

-----------------------------------------------------------------------
-- Auto-reload cuando cambian archivos externamente
-----------------------------------------------------------------------
autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup('checktime'),
  desc = 'Comprobar cambios externos en archivos',
  callback = function()
    if vim.bo.buftype == '' and vim.api.nvim_buf_is_valid(0) then
      vim.cmd('checktime')
    end
  end,
})

-----------------------------------------------------------------------
-- Highlights para nvim-cmp
-----------------------------------------------------------------------
local function set_cmp_highlights()
  vim.schedule(function()
    -- Links al tema actual en vez de colores fijos de VS Code.
    local highlights = {
      CmpItemAbbrDeprecated = { link = 'Comment', strikethrough = true },
      CmpItemAbbrMatch = { link = 'Special' },
      CmpItemAbbrMatchFuzzy = { link = 'CmpItemAbbrMatch' },
      CmpItemKindVariable = { link = 'Identifier' },
      CmpItemKindInterface = { link = 'Type' },
      CmpItemKindText = { link = 'String' },
      CmpItemKindFunction = { link = 'Function' },
      CmpItemKindMethod = { link = 'Function' },
      CmpItemKindKeyword = { link = 'Keyword' },
      CmpItemKindProperty = { link = 'Identifier' },
      CmpItemKindUnit = { link = 'Number' },
    }

    for name, opts in pairs(highlights) do
      pcall(vim.api.nvim_set_hl, 0, name, opts)
    end
  end)
end

autocmd({ 'ColorScheme', 'VimEnter' }, {
  group = augroup('cmp_hls'),
  desc = 'Aplicar colores personalizados a nvim-cmp',
  callback = set_cmp_highlights,
})

-----------------------------------------------------------------------
-- Redimensionar splits al cambiar tamaño
-----------------------------------------------------------------------
autocmd('VimResized', {
  group = augroup('resize_splits'),
  desc = 'Redistribuir ventanas al cambiar tamaño',
  callback = function()
    local current_tab = vim.api.nvim_get_current_tabpage()

    vim.cmd('tabdo wincmd =')

    if vim.api.nvim_tabpage_is_valid(current_tab) then
      vim.api.nvim_set_current_tabpage(current_tab)
    end
  end,
})

-----------------------------------------------------------------------
-- Resaltado al copiar (yank)
-----------------------------------------------------------------------
autocmd('TextYankPost', {
  group = augroup('highlight_yank'),
  desc = 'Resaltar texto copiado',
  callback = function()
    pcall(vim.highlight.on_yank, {
      higroup = 'IncSearch',
      timeout = 152,
    })
  end,
})

-----------------------------------------------------------------------
-- Cerrar buffers auxiliares con q
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

    vim.keymap.set('n', 'q', '<cmd>close<cr>', {
      buffer = ev.buf,
      silent = true,
      nowait = true,
      desc = 'Cerrar ventana auxiliar',
    })
  end,
})

-----------------------------------------------------------------------
-- Optimización de archivos grandes
-----------------------------------------------------------------------
local LARGE_FILE_SIZE = require('utils').large_file_size

autocmd('BufReadPre', {
  group = augroup('large_file_optimizations'),
  desc = 'Reducir consumo en archivos grandes',
  callback = function(ev)
    local file = ev.match or ev.file

    if not file or file == '' then
      return
    end

    local ok, stat = pcall(vim.uv.fs_stat, file)

    if not ok or not stat or not stat.size then
      return
    end

    if stat.size > LARGE_FILE_SIZE then
      vim.b[ev.buf].large_file = true

      vim.bo[ev.buf].syntax = 'OFF'
      vim.bo[ev.buf].swapfile = false
      vim.bo[ev.buf].undofile = false
      vim.bo[ev.buf].modeline = false

      -- foldmethod/foldenable/spell/wrap son window-local: se aplican cuando
      -- el buffer ya está asociado a una ventana.
      vim.schedule(function()
        local win = vim.fn.bufwinid(ev.buf)

        if win == -1 then
          return
        end

        vim.wo[win].foldmethod = 'manual'
        vim.wo[win].foldenable = false
        vim.wo[win].spell = false
        vim.wo[win].wrap = false
      end)
    end
  end,
})

-----------------------------------------------------------------------
-- Restaurar última posición del cursor
-----------------------------------------------------------------------
autocmd('BufReadPost', {
  group = augroup('restore_last_cursor'),
  desc = 'Restaurar posición anterior del cursor',
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(ev.buf)

    if mark[1] > 0 and mark[1] <= line_count then
      local win = vim.fn.bufwinid(ev.buf)

      if win ~= -1 then
        pcall(vim.api.nvim_win_set_cursor, win, {
          mark[1],
          mark[2],
        })
      end
    end
  end,
})

local agroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd


local augroup = function(name)
  return agroup(name, { clear = true })
end

local fmt_group = agroup('autoformat_cmds', { clear = true })

autocmd('LspAttach', {
  group = fmt_group,
  desc = 'Configurar formateo al guardar',
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client or not client.supports_method('textDocument/formatting') then
      return
    end

    autocmd('BufWritePre', {
      group = fmt_group,
      buffer = event.buf,
      desc = 'Formatear antes de guardar',
      callback = function()
        if vim.b._formatting_disabled then return end
        vim.lsp.buf.format({
          bufnr = event.buf,
          async = false,
          timeout_ms = 10000,
        })
      end,
    })
  end,
})

-- Auto crear directorio antes de guardar el archivo
autocmd('BufWritePre', {
  group = augroup('auto_create_dir'),
  callback = function(event)
    if event.file and not event.file:match('^%w%w+:[\\/][\\/]') then
      local file = vim.uv.fs_realpath(event.file) or event.file
      vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
    end
  end,
})

-- Habilitar el ajuste de texto y la corrección ortográfica en archivos específicos
autocmd('FileType', {
  pattern = { 'gitcommit', 'markdown', 'NeogitCommitMessage' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Desvincular snippet de Luasnip al mantener el cursor
autocmd('CursorHold', {
  callback = function()
    local status_ok, luasnip = pcall(require, 'luasnip')
    if status_ok and luasnip.expand_or_jumpable() then
      vim.cmd([[silent! lua require("luasnip").unlink_current()]])
    end
  end,
})

-- Eliminar snippet de Luasnip al salir de modo de inserción
autocmd('InsertLeave', {
  callback = function()
    local luasnip = require('luasnip')
    if luasnip.session.current_nodes[vim.api.nvim_get_current_buf()] and not luasnip.session.jump_active then
      luasnip.unlink_current()
    end
  end,
})

-- Auto-reload archivo cuando cambie
autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup('checktime'),
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd('checktime')
    end
  end,
})

-- Resaltado de la lista de autocompletado
local set_cmp_highlights = function()
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

autocmd('TextChanged', {
  callback = set_cmp_highlights,
})

-- Eliminar espacios en blanco antes de guardar
autocmd('BufWritePre', {
  group = augroup('trim_trailing_spaces'),
  callback = function()
    vim.cmd([[%s/\s\+$//e]])
  end,
})

-- Redimensionar divisores al cambiar el tamaño de la ventana
autocmd('VimResized', {
  group = augroup('resize_splits'),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd('tabdo wincmd =')
    vim.cmd('tabnext ' .. current_tab)
  end,
})

-- Resaltado al hacer yank
autocmd('TextYankPost', {
  group = augroup('highlight_yank'),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Cerrar ciertos tipos de archivo con la tecla <q>
autocmd('FileType', {
  group = augroup('close_with_q'),
  pattern = {
    'PlenaryTestPopup', 'help', 'lspinfo', 'notify', 'qf', 'query', 'spectre_panel',
    'startuptime', 'tsplayground', 'neotest-output', 'checkhealth', 'neotest-summary', 'neotest-output-panel',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
  end,
})

-- Optimizaciones para archivos grandes
autocmd('BufReadPre', {
  group = augroup('large_file_optimizations'),
  callback = function()
    local max_size = 100 * 1024 -- 100 KB
    local file_size = vim.fn.getfsize(vim.fn.expand('<afile>'))
    if file_size > max_size then
      vim.cmd('syntax off')
      vim.cmd('setlocal noswapfile bufhidden=unload')
      vim.cmd('setlocal noundofile')
      vim.cmd('setlocal nofoldenable')
    end
  end,
})

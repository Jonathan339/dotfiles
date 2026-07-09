-- lua/plugins/luasnip/init.lua
return {
  'L3MON4D3/LuaSnip',
  event = 'InsertEnter',
  dependencies = {
    'rafamadriz/friendly-snippets',
    'benfowler/telescope-luasnip.nvim',
  },
  build = (function()
    return (vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1) and 'make install_jsregexp' or nil
  end)(),
  config = function()
    local ls = require('luasnip')

    ls.config.set_config({
      history = true,
      updateevents = 'TextChanged,TextChangedI',
      enable_autosnippets = true,
      region_check_events = 'CursorMoved,CursorHold,InsertEnter',
      delete_check_events = 'TextChanged,InsertLeave',
      store_selection_keys = '<Tab>',
    })

    -- Compartir snippets entre filetypes
    ls.filetype_extend('javascriptreact', { 'html' })
    ls.filetype_extend('typescriptreact', { 'html' })
    ls.filetype_extend('typescript', { 'javascript' })
    ls.filetype_extend('typescriptreact', { 'javascriptreact' })

    -- Cargar VSCode snippets
    pcall(function()
      require('luasnip.loaders.from_vscode').lazy_load()
    end)

    -- Cargar snippets Lua propios (recarga en caliente al guardar)
    local custom_dir = vim.fn.stdpath('config') .. '/lua/plugins/luasnip/snippets'
    local lua_loader = require('luasnip.loaders.from_lua')
    pcall(lua_loader.lazy_load, { paths = custom_dir })

    -- Autoreload de snippets propios al guardar
    vim.api.nvim_create_autocmd('BufWritePost', {
      pattern = custom_dir .. '/**/*.lua',
      callback = function()
        pcall(lua_loader.load, { paths = custom_dir })
        pcall(vim.notify, 'Snippets recargados', vim.log.levels.INFO)
      end,
    })

    --------------------------------------------------------------------
    -- Keymaps cómodos
    --------------------------------------------------------------------
    local map = vim.keymap.set
    local opts = { silent = true, noremap = true }

    -- Expandir o saltar a siguiente posición
    map({ 'i', 's' }, '<C-k>', function()
      if ls.expand_or_jumpable() then
        ls.expand_or_jump()
      end
    end, vim.tbl_extend('force', opts, { desc = 'LuaSnip expand/jump' }))

    -- Saltar hacia atrás
    map({ 'i', 's' }, '<C-j>', function()
      if ls.jumpable(-1) then
        ls.jump(-1)
      end
    end, vim.tbl_extend('force', opts, { desc = 'LuaSnip jump back' }))

    -- Cambiar elección (choice nodes)
    map({ 'i', 's' }, '<C-l>', function()
      if ls.choice_active() then
        ls.change_choice(1)
      end
    end, vim.tbl_extend('force', opts, { desc = 'LuaSnip change choice' }))

    -- Desvincular snippet actual (por si queda “enganchado”)
    map({ 'i', 'n', 's' }, '<C-u>', function()
      pcall(ls.unlink_current)
    end, vim.tbl_extend('force', opts, { desc = 'LuaSnip unlink current' }))
  end,
}

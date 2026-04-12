-- lua/plugins/vim-visual-multi/init.lua
return {
  'mg979/vim-visual-multi',
  branch = 'master',
  -- carga perezosa al presionar atajos típicos
  keys = {
    { '<C-n>', mode = { 'n', 'x' }, desc = 'VM: Find Under / Add cursor' },
    { 'g<C-n>', mode = { 'n', 'x' }, desc = 'VM: Find Subword Under' },
    -- estas dos son solo para forzar el lazy-load si las usás
    { '<M-Up>', mode = 'n', desc = 'VM: Add cursor up (terminal permitting)' },
    { '<M-Down>', mode = 'n', desc = 'VM: Add cursor down (terminal permitting)' },
  },
  init = function()
    -- No tocar la statusline (dejamos a lualine)
    vim.g.VM_set_statusline = 0
    -- Menos ruido al salir / avisos
    vim.g.VM_silent_exit = 1
    vim.g.VM_show_warnings = 0
    -- Resaltado sobrio y búsqueda “smart case”
    vim.g.VM_highlight_matches = 'underline'
    vim.g.VM_case_setting = 'smart'
    -- Si usás mouse y tu terminal lo soporta
    vim.g.VM_mouse_mappings = 1

    -- Mantener los mapeos por defecto (Ctrl-n, g-Ctrl-n, etc.)
    -- Si querés redefinirlos, descomentá y ajustá:
    -- vim.g.VM_default_mappings = 0
    -- vim.g.VM_maps = {
    --   ["Find Under"]         = "<C-d>",
    --   ["Find Subword Under"] = "g<C-d>",
    --   ["Select Cursor Down"] = "<M-j>",
    --   ["Select Cursor Up"]   = "<M-k>",
    --   ["Switch Mode"]        = "<Tab>",
    -- }

    -- Desactivar en buffers auxiliares (por si abrís estos paneles)
    vim.api.nvim_create_autocmd('FileType', {
      pattern = {
        'neo-tree',
        'oil',
        'TelescopePrompt',
        'lazy',
        'mason',
        'notify',
        'noice',
        'help',
        'qf',
        'spectre_panel',
        'toggleterm',
      },
      callback = function()
        vim.b.VM_maps = { ['i'] = false, ['n'] = false, ['x'] = false }
      end,
    })
  end,
}

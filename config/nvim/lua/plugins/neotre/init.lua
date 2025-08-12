return {
  'nvim-neo-tree/neo-tree.nvim',
  branch = 'v3.x',
  cmd = { 'Neotree' },
  keys = {
    { '<leader>n', '<cmd>Neotree toggle<CR>', desc = 'Neo-tree: toggle' },
    { '<leader>f', '<cmd>Neotree reveal<CR>', desc = 'Neo-tree: reveal current file' },
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  config = function()
    require('neo-tree').setup({
      close_if_last_window = true,
      popup_border_style = 'rounded',
      use_popups_for_input = true,
      enable_git_status = true,
      enable_diagnostics = true,

      source_selector = {
        winbar = true,
        content_layout = 'center',
        sources = {
          { source = 'filesystem', display_name = '  Files ' },
          { source = 'buffers', display_name = '  Buffers ' },
          { source = 'git_status', display_name = '  Git ' },
        },
      },

      default_component_configs = {
        icon = {
          folder_closed = '',
          folder_open = '',
          folder_empty = '',
          default = '',
        },
        modified = { symbol = '●' },
        name = {
          trailing_slash = true,
          use_git_status_colors = true,
          highlight_opened_files = 'bold',
        },
        git_status = {
          symbols = {
            added = '',
            deleted = '',
            modified = '',
            renamed = '',
            untracked = '',
            ignored = '',
            unstaged = '',
            staged = '',
            conflict = '',
          },
        },
        diagnostics = {
          symbols = { hint = ' ', info = ' ', warn = ' ', error = ' ' },
        },
      },

      window = {
        position = 'left',
        width = 32,
        mapping_options = { noremap = true, nowait = true },
        mappings = {
          ['<space>'] = 'toggle_node',
          ['<CR>'] = 'open',
          ['o'] = 'open',
          ['S'] = 'open_split',
          ['s'] = 'open_vsplit',
          ['t'] = 'open_tabnew',
          ['C'] = 'close_node',
          ['R'] = 'refresh',
          ['a'] = { 'add', config = { show_path = 'relative' } },
          ['A'] = 'add_directory',
          ['d'] = 'delete',
          ['r'] = 'rename',
          ['y'] = 'copy_to_clipboard',
          ['x'] = 'cut_to_clipboard',
          ['p'] = 'paste_from_clipboard',
          ['H'] = 'toggle_hidden',
          ['.'] = 'set_root',
          ['u'] = 'navigate_up',
          ['q'] = 'close_window',
        },
      },

      filesystem = {
        filtered_items = {
          visible = false,
          hide_dotfiles = true,
          hide_gitignored = true,
          hide_by_name = { '.git', 'node_modules', '.cache', '.DS_Store' },
        },
        follow_current_file = { enabled = true, leave_dirs_open = true },
        group_empty_dirs = true,
        bind_to_cwd = false,
        use_libuv_file_watcher = true,
        -- 👉 Importante: como Oil es tu file explorer por defecto, no hijackear netrw
        hijack_netrw_behavior = 'disabled',
      },

      buffers = {
        follow_current_file = { enabled = true },
        group_empty_dirs = true,
        show_unloaded = true,
      },

      git_status = {
        window = { position = 'float' },
      },

      -- Opcional: al abrir un archivo, cerrar el panel
      event_handlers = {
        {
          event = 'file_opened',
          handler = function(_)
            require('neo-tree.command').execute({ action = 'close' })
          end,
        },
      },
    })
  end,
}

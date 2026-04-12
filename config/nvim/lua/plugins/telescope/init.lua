local M = {
  'nvim-telescope/telescope.nvim',
  cmd = 'Telescope',
  -- También podés usar event = "VeryLazy" si preferís lazy loading por eventos
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-live-grep-args.nvim',
    'nvim-telescope/telescope-file-browser.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        -- Requiere make y toolchain C para compilar
        return vim.fn.executable('make') == 1
      end,
    },
  },
}

M.config = function()
  local telescope = require('telescope')
  local actions = require('telescope.actions')
  local lga_actions = require('telescope-live-grep-args.actions')

  telescope.setup({
    defaults = {
      vimgrep_arguments = {
        'rg',
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case',
        '--hidden',
        '--glob',
        '!.git/*',
      },
      file_ignore_patterns = { 'node_modules', '.git/', 'dist/', 'build/' },
      prompt_prefix = '❯ ',
      selection_caret = '❯ ',
      layout_strategy = 'horizontal',
      layout_config = {
        width = 0.95,
        height = 0.85,
        prompt_position = 'bottom',
        horizontal = {
          preview_width = function(_, cols)
            return math.floor(cols * (cols > 200 and 0.5 or 0.7))
          end,
        },
      },
      sorting_strategy = 'descending',
      scroll_strategy = 'cycle',
      mappings = {
        i = {
          ['<C-n>'] = actions.move_selection_next,
          ['<C-p>'] = actions.move_selection_previous,
        },
      },
    },

    pickers = {
      find_files = {
        find_command = { 'rg', '--files', '--hidden', '--glob', '!.git/*' },
      },
    },

    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = 'smart_case',
      },

      live_grep_args = {
        auto_quoting = true,
        mappings = {
          i = {
            ['<C-k>'] = lga_actions.quote_prompt(),
            ['<C-i>'] = lga_actions.quote_prompt({ postfix = ' --iglob ' }),
          },
        },
      },

      file_browser = {
        grouped = true,
        hijack_netrw = true,
        hidden = true,
      },
    },
  })

  local function safe_load(ext)
    pcall(telescope.load_extension, ext)
  end

  safe_load('fzf')
  safe_load('file_browser')
  safe_load('live_grep_args')
end

return M

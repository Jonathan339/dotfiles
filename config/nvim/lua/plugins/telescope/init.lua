local M = {
  'nvim-telescope/telescope.nvim',
  event = 'VeryLazy',
  tag = '0.1.8',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-live-grep-args.nvim',
    'nvim-telescope/telescope-file-browser.nvim',
  },
}

M.config = function()
  local telescope = require('telescope')
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  -- Configurar las opciones predeterminadas de Telescope
  telescope.setup({
    defaults = {
      file_ignore_patterns = { 'node_modules' },
      prompt_prefix = '❯ ',
      selection_caret = '❯ ',
      winblend = 0,
      layout_strategy = 'horizontal',
      layout_config = {
        width = 0.95,
        height = 0.85,
        prompt_position = 'bottom',
        horizontal = {
          preview_width = function(_, cols, _)
            if cols > 200 then
              return math.floor(cols * 0.5)
            else
              return math.floor(cols * 0.7)
            end
          end,
        },
      },
      selection_strategy = 'reset',
      sorting_strategy = 'descending',
      scroll_strategy = 'cycle',
      color_devicons = true,
      mappings = {
        i = {
          ['<C-n>'] = 'move_selection_next',
          ['<C-y>'] = function(prompt_bufnr)
            local entry = action_state.get_selected_entry()
            if entry then
              action_state.get_current_picker(prompt_bufnr):reset_prompt(entry.ordinal)
            end
          end,
        },
      },
    },
  })

  -- Cargar extensiones adicionales de Telescope
  telescope.load_extension('file_browser')
  telescope.load_extension('live_grep_args')
end

return M

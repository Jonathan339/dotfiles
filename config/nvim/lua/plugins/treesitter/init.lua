return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  dependencies = { 'nvim-treesitter/playground', cmd = 'TSPlaygroundToggle' },
  config = function()
    local configs = require('nvim-treesitter.configs')
    configs.setup({
      ensure_installed = {
        'bash',
        'css',
        'go',
        'gomod',
        'html',
        'http',
        'javascript',
        'jsdoc',
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'nix',
        'org',
        'php',
        'phpdoc',
        'python',
        'query',
        'regex',
        'rust',
        'sql',
        'svelte',
        'typescript',
        'vim',
        'yaml',
      },

      -- https://github.com/nvim-treesitter/playground#query-linter
      query_linter = {
        enable = true,
        use_virtual_text = true,
        lint_events = { 'BufWrite', 'CursorHold' },
      },
      playground = {
        enable = true,
        disable = {},
        updatetime = 25,        -- Debounced time for highlighting nodes in the playground from source code
        persist_queries = true, -- Whether the query persists across vim sessions
        keybindings = {
          toggle_query_editor = 'o',
          toggle_hl_groups = 'i',
          toggle_injected_languages = 't',
          toggle_anonymous_nodes = 'a',
          toggle_language_display = 'I',
          focus_language = 'f',
          unfocus_language = 'F',
          update = 'R',
          goto_node = '<cr>',
          show_help = '?',
        },
      },
      highlight = { enable = true },
      indent = { enable = true },
      autotag = { enable = true },
    })
  end,
}

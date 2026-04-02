---@diagnostic disable: undefined-global
--- lua/plugins/treesitter/init.lua
return {
  'nvim-treesitter/nvim-treesitter',
  event = { 'BufReadPost', 'BufNewFile' },
  cmd = { 'TSInstall', 'TSBufEnable', 'TSBufDisable', 'TSModuleInfo' },
  build = ':TSUpdate',

  config = function()
    -- Mapear filetypes de React a parsers correctos
    pcall(function()
      vim.treesitter.language.register('tsx', 'typescriptreact')
      vim.treesitter.language.register('javascript', 'javascriptreact')
    end)

    local ts = require('nvim-treesitter.configs')

    ts.setup({
      -- Tu baseline de parsers + algunos comunes
      ensure_installed = {
        'bash',
        'c',
        'cpp',
        'css',
        'dockerfile',
        'elixir',
        'erlang',
        'heex',
        'eex',
        'go',
        'html',
        'java',
        'javascript',
        'jq',
        'json',
        'kotlin',
        'lua',
        'markdown',
        'markdown_inline',
        'nix',
        'python',
        'query',
        'ruby',
        'rust',
        'terraform',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
      },

      auto_install = true, -- instala en caliente si falta un parser
      sync_install = false,
      ignore_install = {},

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
        -- Desactivar highlight en archivos grandes (evita lag)
        disable = function(_, buf)
          local max = 500 * 1024 -- 500 KB
          local ok, stat = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stat and stat.size and stat.size > max then
            return true
          end
          return false
        end,
      },

      indent = {
        enable = true,
        disable = { 'python', 'yaml' }, -- suelen romper indent
      },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = 'gnn',
          node_incremental = 'grn',
          scope_incremental = 'grc',
          node_decremental = 'grm',
        },
      },

      -- ¡Importante! `context_commentstring` ya NO va aquí.
      -- Lo configuramos desde el plugin `nvim-ts-context-commentstring`.

      -- Playground + linter de queries (como tenías)
      query_linter = {
        enable = true,
        use_virtual_text = true,
        lint_events = { 'BufWrite', 'CursorHold' },
      },
      
    })
  end,
}

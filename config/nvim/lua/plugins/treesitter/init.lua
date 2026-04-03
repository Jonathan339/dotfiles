---@diagnostic disable: undefined-global
return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false, -- nvim-treesitter upstream no soporta lazy-loading
  build = ':TSUpdate',
  cmd = { 'TSInstall', 'TSUpdate', 'TSBufEnable', 'TSBufDisable', 'TSModuleInfo' },

  config = function()
    local uv = vim.uv or vim.loop
    local warned_langs = {}

    local ensure_installed = {
      'bash',
      'c',
      'cpp',
      'css',
      'dockerfile',
      'elixir',
      'erlang',
      'eex',
      'go',
      'heex',
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
      'yaml',
    }

    local function is_large_file(buf)
      local max = 500 * 1024
      local ok, stat = pcall(uv.fs_stat, vim.api.nvim_buf_get_name(buf))
      return ok and stat and stat.size and stat.size > max
    end

    local function ts_can_highlight(lang, buf)
      if not lang or not buf or not vim.api.nvim_buf_is_valid(buf) then
        return false
      end
      if is_large_file(buf) then
        return false
      end

      local ok_parser, parser = pcall(vim.treesitter.get_parser, buf, lang)
      if not ok_parser or not parser then
        return false
      end

      local ok_parse, trees = pcall(parser.parse, parser)
      if not ok_parse or type(trees) ~= 'table' or not trees[1] then
        return false
      end

      local ok_root, root = pcall(function()
        return trees[1]:root()
      end)
      return ok_root and root and type(root.range) == 'function'
    end

    local function warn_once(lang)
      if warned_langs[lang] then
        return
      end
      warned_langs[lang] = true
      vim.schedule(function()
        vim.notify(
          ('Treesitter desactivado para "%s" (parser incompatible o desactualizado). Ejecutá :TSUpdate y reiniciá Neovim.'):format(lang),
          vim.log.levels.WARN
        )
      end)
    end

    -- Mapear filetypes React -> parser correcto
    pcall(function()
      vim.treesitter.language.register('tsx', 'typescriptreact')
      vim.treesitter.language.register('javascript', 'javascriptreact')
    end)

    local has_new_api, ts = pcall(require, 'nvim-treesitter')
    if has_new_api and type(ts.setup) == 'function' then
      -- API nueva (Neovim 0.12+)
      ts.setup({})
      if type(ts.install) == 'function' then
        pcall(ts.install, ensure_installed)
      end

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(args.match) or args.match
          if not ts_can_highlight(lang, args.buf) then
            warn_once(lang)
            return
          end
          pcall(vim.treesitter.start, args.buf, lang)
        end,
      })
      return
    end

    -- Fallback API legacy (rama master bloqueada)
    local ok_configs, configs = pcall(require, 'nvim-treesitter.configs')
    if ok_configs and type(configs.setup) == 'function' then
      configs.setup({
        ensure_installed = ensure_installed,
        auto_install = true,
        sync_install = false,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
          disable = function(lang, buf)
            if not ts_can_highlight(lang, buf) then
              warn_once(lang)
              return true
            end
            return false
          end,
        },
        indent = {
          enable = true,
          disable = { 'python', 'yaml' },
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
        query_linter = {
          enable = true,
          use_virtual_text = true,
          lint_events = { 'BufWrite', 'CursorHold' },
        },
      })
      return
    end

    vim.notify(
      'No se pudo inicializar nvim-treesitter: API no reconocida.',
      vim.log.levels.ERROR
    )
  end,
}

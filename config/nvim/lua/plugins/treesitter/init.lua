-- lua/plugins/treesitter/init.lua
-- nvim-treesitter rama main (2.x): el resaltado lo hace Neovim con
-- vim.treesitter.start() y los parsers se piden con ts.install(). Ya no existen
-- las claves ensure_installed/highlight/indent del setup 1.x.
local CONFIG_DIR = vim.fn.stdpath('config')
local CLI_DIR = CONFIG_DIR .. '/node_modules/.bin'

local PARSERS = {
  'astro',
  'bash',
  'c',
  'cmake',
  'cpp',
  'css',
  'diff',
  'dockerfile',
  'fish',
  'git_config',
  'gitcommit',
  'gitignore',
  'go',
  'graphql',
  'html',
  'http',
  'java',
  'javascript',
  'jsdoc',
  'json',
  'lua',
  'luadoc',
  'luap',
  'markdown',
  'markdown_inline',
  'printf',
  'python',
  'query',
  'regex',
  'rust',
  'scss',
  'solidity',
  'sql',
  'svelte',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'vue',
  'xml',
  'yaml',
}

local function tree_sitter_path()
  local local_cli = CLI_DIR .. '/tree-sitter'
  if vim.fn.executable(local_cli) == 1 then
    return local_cli
  end
  if vim.fn.executable('tree-sitter') == 1 then
    return 'tree-sitter'
  end
end

-- El CLI local debe estar en PATH también para :checkhealth y :TSUpdate.
local function add_cli_to_path()
  if vim.fn.isdirectory(CLI_DIR) == 1 and not vim.env.PATH:find(CLI_DIR, 1, true) then
    vim.env.PATH = CLI_DIR .. ':' .. vim.env.PATH
  end
end

-- main compila los parsers con el CLI de tree-sitter: si falta, lo instala con bun
local function ensure_cli(callback)
  add_cli_to_path()
  if tree_sitter_path() then
    callback()
    return
  end

  local bun = 'bun'
  if vim.fn.executable(bun) ~= 1 then
    bun = vim.env.HOME .. '/.bun/bin/bun'
  end
  if vim.fn.executable(bun) ~= 1 then
    vim.notify('tree-sitter-cli no encontrado y bun no está instalado', vim.log.levels.ERROR)
    return
  end

  vim.notify('Instalando tree-sitter-cli local con bun...', vim.log.levels.INFO)
  vim.system({ bun, 'install' }, { text = true, cwd = CONFIG_DIR }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        vim.notify('Error instalando tree-sitter-cli: ' .. (obj.stderr or ''), vim.log.levels.ERROR)
        return
      end
      callback()
    end)
  end)
end

local function install_missing()
  local ok, ts = pcall(require, 'nvim-treesitter')
  if not ok then
    return
  end
  local missing = vim.tbl_filter(function(lang)
    return not vim.tbl_contains(ts.get_installed(), lang)
  end, PARSERS)
  if #missing == 0 then
    return
  end
  ensure_cli(function()
    ts.install(missing)
  end)
end

return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  -- upstream: "This plugin does not support lazy-loading"
  lazy = false,
  build = function()
    add_cli_to_path()
    vim.cmd('TSUpdate')
  end,
  config = function()
    add_cli_to_path()

    -- MDX no tiene parser propio: se renderiza con el de Markdown.
    vim.filetype.add({
      extension = {
        mdx = 'mdx',
      },
    })
    vim.treesitter.language.register('markdown', 'mdx')

    -- main no activa el resaltado: hay que hacerlo por filetype.
    -- Además, si el lenguaje trae queries de indent, se usa la indentación
    -- de nvim-treesitter (mejor que la de ftplugin para JS/TS, etc.).
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('ts_highlight', { clear = true }),
      callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not lang or not vim.treesitter.language.add(lang) then
          return
        end

        if not vim.treesitter.highlighter.active[ev.buf] then
          vim.treesitter.start(ev.buf, lang)
        end

        local ok, query = pcall(vim.treesitter.query.get, lang, 'indents')
        if ok and query then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })

    -- instalar en segundo plano lo que falte, sin bloquear el arranque
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      once = true,
      callback = install_missing,
    })
  end,
}

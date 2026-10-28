-- lua/plugins/lsp/handlers.lua
-- Cada handler solo declara lo específico del servidor: utils.setup_lsp inyecta
-- capabilities/on_init/on_attach de lsp/defaults.lua.
--
-- root_dir usa la firma de Neovim 0.11+: fun(bufnr, on_dir). La firma vieja
-- fun(fname) recibía el número de buffer y rompía vim.fs.find.
local M = {}
local setup = require('utils').setup_lsp

local function simple(name)
  M[name] = function()
    setup(name, {})
  end
end

simple('bashls')
simple('pyright')
simple('ruff')
simple('html')
simple('cssls')
simple('yamlls')
simple('taplo')

M['clangd'] = function()
  setup('clangd', {
    cmd = {
      'clangd',
      '--clang-tidy',
      '--clang-tidy-checks=-*,clang-*,bugprone-*,performance-*,readability-*,portability-*',
      '--header-insertion=iwyu',
    },
  })
end

-- typos (spell checker multi-idioma por LSP)
M['typos_lsp'] = function()
  setup('typos_lsp', {
    cmd = { 'typos-lsp', '--stdio' },
  })
end

-- JSON LS: nvim-lspconfig ya inyecta los schemas de schemastore
M['jsonls'] = function()
  setup('jsonls', {
    settings = {
      json = {
        validate = { enable = true },
      },
    },
  })
end

local function ts_handler(name)
  return function()
    setup(name, {
      handlers = {
        ['textDocument/definition'] = function(err, result, ctx, ...)
          if type(result) == 'table' and #result > 1 then
            result = { result[1] }
          end
          vim.lsp.handlers['textDocument/definition'](err, result, ctx, ...)
        end,
      },
      root_dir = function(bufnr, on_dir)
        local root = vim.fs.root(bufnr, { 'tsconfig.json', 'jsconfig.json', 'package.json' })
          or vim.fs.root(bufnr, '.git')
          or vim.uv.cwd()
        on_dir(root)
      end,
      settings = {
        typescript = {
          inlayHints = {
            includeInlayEnumMemberValueHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayParameterNameHints = 'min',
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayVariableTypeHints = true,
          },
        },
        javascript = {
          inlayHints = {
            includeInlayEnumMemberValueHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayParameterNameHints = 'min',
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayVariableTypeHints = true,
          },
        },
      },
      on_attach = function(_, bufnr)
        if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
          pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
        end
      end,
    })
  end
end

M['vtsls'] = ts_handler('vtsls')

-- ESLint LSP (solo diagnósticos y code actions)
M['eslint'] = function()
  setup('eslint', {
    root_dir = function(bufnr, on_dir)
      local root = vim.fs.root(bufnr, {
        '.eslintrc',
        '.eslintrc.js',
        '.eslintrc.cjs',
        '.eslintrc.json',
        '.eslintrc.yaml',
        '.eslintrc.yml',
        'eslint.config.js',
        'eslint.config.cjs',
        'eslint.config.mjs',
        'eslint.config.ts',
        'package.json',
      }) or vim.fs.root(bufnr, '.git') or vim.uv.cwd()
      on_dir(root)
    end,
    filetypes = {
      'javascript',
      'javascriptreact',
      'typescript',
      'typescriptreact',
      'vue',
      'svelte',
      'astro',
    },
    settings = {
      codeAction = {
        disableRuleComment = { enable = true, location = 'separateLine' },
        showDocumentation = { enable = true },
      },
      codeActionOnSave = { enable = false, mode = 'all' },
      format = false,
      validate = 'on',
      workingDirectory = { mode = 'location' },
    },
  })
end

-- Lua (Neovim)
M['lua_ls'] = function()
  setup('lua_ls', {
    settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        diagnostics = {
          globals = { 'vim', 'it', 'describe', 'before_each', 'after_each' },
        },
        workspace = {
          checkThirdParty = false,
          library = vim.api.nvim_get_runtime_file('', true),
        },
        format = { enable = false },
        telemetry = { enable = false },
        completion = { callSnippet = 'Replace' },
      },
    },
  })
end

M['tailwindcss'] = function()
  setup('tailwindcss', {
    root_dir = function(bufnr, on_dir)
      local root = vim.fs.root(bufnr, {
        'tailwind.config.js',
        'tailwind.config.cjs',
        'tailwind.config.mjs',
        'tailwind.config.ts',
      }) or vim.fs.root(bufnr, '.git') or vim.uv.cwd()
      on_dir(root)
    end,
  })
end

-- emmet_ls cubre la expansión de abreviaturas vía cmp (reemplaza nvim-emmet)
M['emmet_ls'] = function()
  setup('emmet_ls', {
    filetypes = {
      'html',
      'xml',
      'javascriptreact',
      'typescriptreact',
      'svelte',
      'vue',
      'astro',
      'css',
      'scss',
    },
    root_dir = function(bufnr, on_dir)
      on_dir(vim.fs.root(bufnr, '.git') or vim.uv.cwd())
    end,
  })
end

-- marksman (Markdown LSP)
M['marksman'] = function()
  setup('marksman', {
    root_dir = function(bufnr, on_dir)
      on_dir(vim.fs.root(bufnr, { '.git', '.marksman.toml', 'markdown.json' }) or vim.uv.cwd())
    end,
    settings = {
      markdown = {
        link_validate = { enabled = true },
      },
    },
  })
end

return M

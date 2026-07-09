-- lua/plugins/lsp/handlers.lua
local M = {}
local defaults = require('plugins.lsp.defaults')
local setup = require('utils').setup_lsp
local util = require('lspconfig.util')
local root_pattern = util.root_pattern

local function simple(name)
  M[name] = function()
    setup(name, {
      capabilities = defaults.capabilities,
      on_attach = defaults.on_attach,
      on_init = defaults.on_init,
    })
  end
end

simple('bashls')
simple('pyright')
simple('html')
simple('cssls')
M['clangd'] = function()
  setup('clangd', {
    cmd = {
      'clangd',
      '--clang-tidy',
      '--clang-tidy-checks=-*,clang-*,bugprone-*,performance-*,readability-*,portability-*',
      '--header-insertion=iwyu',
    },
    capabilities = defaults.capabilities,
    on_attach = defaults.on_attach,
    on_init = defaults.on_init,
  })
end

-- EFM (agregador genérico) -> requiere configurar linters en efm-langserver
M['efm'] = function()
  setup('efm', {
    cmd = { 'efm-langserver' },
    init_options = { documentFormatting = false, documentRangeFormatting = false },
    root_dir = root_pattern('.git', '.efm.json', '.efmrc', '.config/efm-langserver/config.yaml'),
    settings = {
      rootMarkers = { '.git/' },
      lintDebounce = '500ms',
    },
  })
end

-- typos (spell checker multi-idioma por LSP)
M['typos_lsp'] = function()
  setup('typos_lsp', {
    cmd = { 'typos-lsp', '--stdio' },
  })
end

-- JSON LS (con schemastore si está)
M['jsonls'] = function()
  local has_schemastore, schemastore = pcall(require, 'schemastore')
  local schemas = has_schemastore and schemastore.json.schemas() or nil

  setup('jsonls', {
    cmd = { 'vscode-json-language-server', '--stdio' },
    filetypes = { 'json', 'jsonc' },
    settings = {
      json = {
        schemas = schemas,
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
      root_dir = function(fname)
        return root_pattern('tsconfig.json', 'jsconfig.json', 'package.json')(fname) or util.find_git_ancestor(fname) or vim.uv.cwd()
      end,
      settings = {
        typescript = {
          inlayHints = {
            includeInlayEnumMemberValueHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayParameterNameHints = 'all',
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = true,
          },
        },
        javascript = {
          inlayHints = {
            includeInlayEnumMemberValueHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayParameterNameHints = 'all',
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = true,
          },
        },
      },
      on_attach = function(client, bufnr)
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
    cmd = { 'vscode-eslint-language-server', '--stdio' },
    root_dir = function(fname)
      return root_pattern('.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json', '.eslintrc.yaml', '.eslintrc.yml', 'eslint.config.js', 'eslint.config.cjs', 'eslint.config.mjs', 'eslint.config.ts', 'package.json')(fname) or util.find_git_ancestor(fname)
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
  local root_pattern = require('lspconfig.util').root_pattern
  setup('tailwindcss', {
    root_dir = root_pattern('.git'),
  })
end

-- emmet_ls (Emmet LSP)
M['emmet_ls'] = function()
  setup('emmet_ls', {
    filetypes = { 'html', 'xml', 'jsx', 'tsx', 'svelte', 'vue', 'astro', 'css', 'scss' },
    root_dir = function(fname)
      return util.find_git_ancestor(fname) or vim.uv.cwd()
    end,
  })
end

-- marksman (Markdown LSP)
M['marksman'] = function()
  setup('marksman', {
    root_dir = function(fname)
      return root_pattern('.git', '.marksman.toml', 'markdown.json')(fname) or util.find_git_ancestor(fname) or vim.uv.cwd()
    end,
    settings = {
      markdown = {
        link_validate = { enabled = true },
      },
    },
  })
end

-- Compat: si algo intenta usar "tsserver", redirigimos a vtsls
M['tsserver'] = function()
  return M['vtsls']()
end

return M

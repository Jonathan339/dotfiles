-- lua/plugins/lsp/handlers.lua
local M = {}
local setup = require('utils').setup_lsp
local util = require('lspconfig.util')
local root_pattern = util.root_pattern

-- dprint LSP (formatea y/o diagnostica con su config local)
M['dprint'] = function()
  setup('dprint', {
    cmd = { 'dprint', 'lsp' },
    filetypes = {
      'javascript',
      'javascriptreact',
      'typescript',
      'typescriptreact',
      'json',
      'jsonc',
      'markdown',
      'python',
      'toml',
      'rust',
      'roslyn',
      'graphql',
    },
    root_dir = root_pattern('dprint.json', '.dprint.json', 'dprint.jsonc', '.dprint.jsonc'),
  })
end

-- EFM (agregador genérico) -> sin formato para no chocar con Conform
M['efm'] = function()
  setup('efm', {
    cmd = { 'efm-langserver' },
    init_options = { documentFormatting = false, documentRangeFormatting = false },
    root_dir = root_pattern('.git', '.efm.json', '.efmrc', '.config/efm-langserver/config.yaml'),
    filetypes = {
      'python',
      'cpp',
      'lua',
      'javascript',
      'typescript',
      'javascriptreact',
      'typescriptreact',
      'html',
      'css',
      'scss',
      'json',
      'yaml',
      'markdown',
      'markdown.pandoc',
      'astro',
      'svelte',
    },
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

-- JSON LS (con schemastore si está) — formatea via Conform (prettier/prettierd)
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
    on_attach = function(client, _)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end,
  })
end

-- TypeScript/JavaScript (nuevo nombre: ts_ls)
M['ts_ls'] = function()
  setup('ts_ls', {
    handlers = {
      ['textDocument/definition'] = function(err, result, ctx, ...)
        if type(result) == 'table' and #result > 1 then
          result = { result[1] }
        end
        vim.lsp.handlers['textDocument/definition'](err, result, ctx, ...)
      end,
    },
    -- Soporte TS/JS: roots comunes
    root_dir = function(fname)
      return root_pattern('tsconfig.json', 'jsconfig.json', 'package.json')(fname) or util.find_git_ancestor(fname) or (vim.uv and vim.uv.cwd() or vim.loop.cwd())
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
      -- evitar doble formateo (Conform se encarga)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
      -- habilitar inlay hints si existe la API
      if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
        pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
      elseif vim.lsp.inlay_hint then
        -- Neovim 0.10 signature antigua: enable(bufnr, true)
        pcall(vim.lsp.inlay_hint, bufnr, true)
      end
    end,
  })
end

-- ESLint LSP (solo diagnósticos y code actions; formato via eslint_d en Conform)
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
      format = false, -- 🔴 no formatea (lo hace Conform)
      validate = 'on',
      workingDirectory = { mode = 'location' },
    },
    on_attach = function(client, _)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end,
  })
end

-- Lua (Neovim)
M['lua_ls'] = function()
  setup('lua_ls', {
    settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        diagnostics = { globals = { 'vim', 'it', 'describe', 'before_each', 'after_each' } },
        workspace = {
          library = vim.api.nvim_get_runtime_file('', true),
          checkThirdParty = false,
        },
        format = { enable = false }, -- usamos stylua vía Conform
        telemetry = { enable = false },
        completion = { callSnippet = 'Replace' },
      },
    },
    on_init = function(client)
      local s = client.config.settings or {}
      s.Lua = s.Lua or {}
      s.Lua.diagnostics = s.Lua.diagnostics or {}
      s.Lua.diagnostics.globals = { 'vim', 'it', 'describe', 'before_each', 'after_each' }
      s.Lua.workspace = s.Lua.workspace or {}
      s.Lua.workspace.checkThirdParty = false
      s.Lua.workspace.library = vim.api.nvim_get_runtime_file('', true)
      client.config.settings = s
      client.notify('workspace/didChangeConfiguration', { settings = s })
    end,
    on_attach = function(client, _)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end,
  })
end

-- Compat: si algo intenta usar "tsserver", redirigimos a ts_ls
M['tsserver'] = function()
  return M['ts_ls']()
end

return M

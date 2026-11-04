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

-- ESLint LSP (fallback: solo si el proyecto no usa Oxlint)
M['eslint'] = function()
  setup('eslint', {
    root_dir = function(bufnr, on_dir)
      -- Oxlint tiene prioridad si está instalado y el proyecto tiene su config.
      -- Así no se duplican diagnósticos en proyectos con ambos linters.
      local has_oxlint = vim.fn.executable('oxlint') == 1
      local oxlint_root = vim.fs.root(bufnr, {
        '.oxlintrc.json',
        '.oxlintrc.jsonc',
        'oxlint.config.ts',
      })
      if has_oxlint and oxlint_root then
        -- No llamamos on_dir(): así Neovim no arranca ESLint en single-file.
        return
      end

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
      })

      -- Soporte para proyectos que definen `eslintConfig` dentro de package.json.
      if not root then
        local pkg_root = vim.fs.root(bufnr, 'package.json')
        if pkg_root then
          local ok, lines = pcall(vim.fn.readfile, pkg_root .. '/package.json')
          if ok and table.concat(lines, '\n'):find('"eslintConfig"', 1, true) then
            root = pkg_root
          end
        end
      end

      -- Sin config de ESLint no arrancamos el servidor (evita el warning
      -- "Unable to find ESLint library" en proyectos que no usan ESLint).
      if root then
        on_dir(root)
      end
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

-- Oxlint LSP: reemplaza a ESLint en proyectos con config de Oxc. Es mucho más
-- rápido (Rust) y cubre +500 reglas de ESLint. El fallback a ESLint vive en el
-- handler de arriba y en Conform (eslint_d/prettier).
local function oxlint_root(bufnr)
  local root = vim.fs.root(bufnr, {
    '.oxlintrc.json',
    '.oxlintrc.jsonc',
    'oxlint.config.ts',
  })
  if root then
    return root
  end

  -- package.json con campo "oxlint" (o Vite+) también cuenta como config.
  local pkg_root = vim.fs.root(bufnr, 'package.json')
  if not pkg_root then
    return nil
  end
  local ok, lines = pcall(vim.fn.readfile, pkg_root .. '/package.json')
  if ok then
    local content = table.concat(lines, '\n')
    if content:find('"oxlint"', 1, true) or content:find('"vite-plus"', 1, true) then
      return pkg_root
    end
  end
end

M['oxlint'] = function()
  setup('oxlint', {
    root_dir = function(bufnr, on_dir)
      local root = oxlint_root(bufnr)
      if root then
        on_dir(root)
      end
    end,
    on_attach = function(client, bufnr)
      vim.api.nvim_buf_create_user_command(bufnr, 'LspOxlintFixAll', function()
        client:exec_cmd({
          title = 'Apply Oxlint automatic fixes',
          command = 'oxc.fixAll',
          arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
        })
      end, { desc = 'Aplicar fixes automáticos de Oxlint' })
    end,
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

-- handlers.lua
local M = {}
-- local lsp = require("lspconfig")
local capabilities = require("plugins.lsp.defaults").capabilities
local on_attach = require("plugins.lsp.defaults").on_attach

-- Función común para configurar LSPs con capabilities y on_attach
local function setup_lsp(server, config)
  require("lspconfig")[server].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    settings = config.settings,
    cmd = config.cmd,
    filetypes = config.filetypes,
    init_options = config.init_options,
    root_dir = config.root_dir,
  })
end

M["efm"] = function()
  setup_lsp("efm", {
    capabilities = capabilities,
    cmd = { "efm-langserver" },
    on_attach = on_attach,
    init_options = { documentFormatting = true },
    root_dir = vim.loop.cwd,
    filetypes = { 'python', 'cpp', 'lua', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'html', 'css', 'scss', 'json', 'yaml', 'markdown', 'markdown.pandoc', 'astro', 'svelte' },
    settings = {
      rootMarkers = { ".git/" },
      lintDebounce = "500ms",
    },
  })
end

M["typos_lsp"] = function()
  setup_lsp("typos_lsp", {
    cmd = { "typos-lsp", "--stdio" },
  })
end

M["jsonls"] = function()
  setup_lsp("jsonls", {
    cmd = { "vscode-json-language-server", "--stdio" },
    filetypes = { "json", "jsonc" },
    init_options = true,
  })
end

M["ts_ls"] = function()
  setup_lsp("ts_ls", {
    ["textDocument/definition"] = function(err, result, ctx, ...)
      if #result > 1 then
        result = { result[1] }
      end
      vim.lsp.handlers["textDocument/definition"](err, result, ctx, ...)
    end,
    root_dir = require("lspconfig/util").root_pattern("tsconfig.json"),
    settings = {
      typescript = {
        inlayHints = {
          includeInlayEnumMemberValueHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
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
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayVariableTypeHintsWhenTypeMatchesName = true,
        },
      },
    },
  })
end

M["tailwindcss"] = function()
  setup_lsp("tailwindcss", {
    cmd = { "tailwindcss-language-server", "--stdio" },
    filetypes = { "css", "scss", "less", "svelte" },
    root_dir = require("lspconfig/util").root_pattern(
      "tailwind.config.js",
      "tailwind.config.ts",
      "tailwind.config.cjs"
    ),
    settings = {
      tailwindCSS = {
        lint = {
          cssConflict = "warning",
          invalidApply = "error",
          invalidConfigPath = "error",
          invalidScreen = "error",
          invalidTailwindDirective = "error",
          recommendedVariantOrder = "warning",
          unusedClass = "warning",
        },
        experimental = {},
        validate = true,
      },
    },
  })
end

M["lua_ls"] = function()
  setup_lsp("lua_ls", {
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim", "it", "describe", "before_each", "after_each" },
        },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false,
        },
        format = {
          enable = true,
        },
      },
    },
  })
end

M["vimls"] = function()
  setup_lsp("vimls", {
    init_options = { isNeovim = true },
  })
end

M["eslint"] = function()
  setup_lsp("eslint", {
    cmd = { "vscode-eslint-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx", "vue", "svelte", "astro" },
    settings = {
      codeAction = {
        disableRuleComment = { enable = true, location = "separateLine" },
        showDocumentation = { enable = true },
      },
      codeActionOnSave = { enable = false, mode = "all" },
      format = true,
      validate = "on",
      workingDirectory = { mode = "location" },
    },
    handlers = {
      ["eslint/confirmESLintExecution"] = function(_, result)
        return result and result.data
      end,
      ["eslint/noLibrary"] = function(_, _)
        vim.notify("ESLint: No library found", vim.log.levels.WARN)
      end,
      ["eslint/openDoc"] = function(_, params)
        if params.url then
          vim.fn.jobstart({ "xdg-open", params.url }, { detach = true })
        end
      end,
      ["eslint/probeFailed"] = function(_, _)
        vim.notify("ESLint: Probe failed", vim.log.levels.ERROR)
      end,
    },
  })
end

M["diagnosticls"] = function()
  setup_lsp("diagnosticls", {
    cmd = { "diagnostic-languageserver", "--stdio" },
  })
end

M["bashls"] = function()
  setup_lsp("bashls", {
    cmd = { "bash-language-server", "start" },
    filetypes = { "sh", "bash", "zsh", "ksh" },
    settings = { bashIde = { globPattern = "*@(.sh|.inc|.bash|.command)" } },
  })
end

M["cssls"] = function()
  setup_lsp("cssls", {
    cmd = { "vscode-css-languageserver", "--stdio" },
    filetypes = { "css", "scss", "less" },
    init_options = {
      useDefaultConfig = true,
      provideFormatter = { provideFormatter = true },
    },
    settings = {
      css = { validate = true },
      less = { validate = true },
      scss = { validate = true },
    },
  })
end

return M

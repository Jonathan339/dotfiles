local M = {}
local setup = require("utils").setup_lsp
local root_pattern = require("lspconfig.util").root_pattern

M["efm"] = function()
  setup("efm", {
    cmd = { "efm-langserver" },
    init_options = { documentFormatting = true },
    root_dir = vim.loop.cwd,
    filetypes = {
      "python", "cpp", "lua", "javascript", "typescript", "javascriptreact",
      "typescriptreact", "html", "css", "scss", "json", "yaml",
      "markdown", "markdown.pandoc", "astro", "svelte",
    },
    settings = {
      rootMarkers = { ".git/" },
      lintDebounce = "500ms",
    },
  })
end

M["typos_lsp"] = function()
  setup("typos_lsp", {
    cmd = { "typos-lsp", "--stdio" },
  })
end

M["jsonls"] = function()
  setup("jsonls", {
    cmd = { "vscode-json-language-server", "--stdio" },
    filetypes = { "json", "jsonc" },
    init_options = true,
  })
end

M["ts_ls"] = function()
  setup("ts_ls", {
    handlers = {
      ["textDocument/definition"] = function(err, result, ctx, ...)
        if #result > 1 then result = { result[1] } end
        vim.lsp.handlers["textDocument/definition"](err, result, ctx, ...)
      end,
    },
    root_dir = root_pattern("tsconfig.json"),
    settings = {
      typescript = {
        inlayHints = {
          includeInlayEnumMemberValueHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayParameterNameHints = "all",
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
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayVariableTypeHintsWhenTypeMatchesName = true,
        },
      },
    },
  })
end

M["eslint"] = function()
  setup("eslint", {
    cmd = { "vscode-eslint-language-server", "--stdio" },
    filetypes = {
      "javascript", "javascriptreact", "javascript.jsx", "typescript",
      "typescriptreact", "typescript.tsx", "vue", "svelte", "astro",
    },
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
  })
end

 M["lua_ls"] = function()
  setup("lua_ls", {
    settings = {
      Lua = {
        diagnostics = { globals = { "vim", "it", "describe", "before_each", "after_each" } },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false,
        },
        format = { enable = true },
        formatOnSave = { enable = true },
        telemetry = { enable = false },
      },
    },
  })
end

return M

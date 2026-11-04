-- lua/plugins/conform/init.lua
local eslintrc_files = {
  '.eslintrc',
  '.eslintrc.cjs',
  '.eslintrc.js',
  '.eslintrc.json',
  '.eslintrc.yaml',
  '.eslintrc.yml',
  'eslint.config.js',
  'eslint.config.cjs',
  'eslint.config.mjs',
  'eslint.config.ts',
}

local function has_eslintrc(_, ctx)
  if not ctx or not ctx.buf then
    return false
  end
  return vim.fs.root(ctx.buf, eslintrc_files) ~= nil
end

local oxfmtrc_files = {
  '.oxfmtrc.json',
  '.oxfmtrc.jsonc',
  'oxfmt.config.ts',
}

-- Conform llama `condition(self, ctx)` para formatters de job. El parámetro
-- importante es el segundo (ctx); el primero es la config del formatter.
local function has_oxfmtrc(_, ctx)
  if not ctx or not ctx.buf then
    return false
  end
  return vim.fs.root(ctx.buf, oxfmtrc_files) ~= nil
end

local function exe(name)
  return vim.fn.executable(name) == 1
end

-- Oxfmt solo se usa si el proyecto tiene config de Oxc y el binario existe.
-- Si no, se cae a ESLint/Prettier como antes.
local function oxfmt_available(bufnr)
  return require('conform').get_formatter_info('oxfmt', bufnr).available
end

local function js_formatters(bufnr)
  if oxfmt_available(bufnr) then
    return { 'oxfmt', 'prettier', stop_after_first = true }
  end
  return { 'eslint_d', 'prettier' }
end

local function oxfmt_or_prettier(bufnr)
  if oxfmt_available(bufnr) then
    return { 'oxfmt', 'prettier', stop_after_first = true }
  end
  return { 'prettier' }
end

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo', 'FormatToggle' },
  config = function()
    -- Filetypes reales de Neovim (jsx/tsx == javascriptreact/typescriptreact)
    local formatters_by_ft = {
      javascript = js_formatters,
      javascriptreact = js_formatters,
      typescript = js_formatters,
      typescriptreact = js_formatters,
      vue = js_formatters,
      svelte = js_formatters,
      astro = js_formatters,
      lua = { 'stylua' },
      python = { 'ruff_organize_imports', 'ruff_format' },
      sh = { 'shfmt' },
      json = oxfmt_or_prettier,
      jsonc = oxfmt_or_prettier,
      yaml = oxfmt_or_prettier,
      markdown = oxfmt_or_prettier,
      css = oxfmt_or_prettier,
      scss = oxfmt_or_prettier,
      less = oxfmt_or_prettier,
      html = oxfmt_or_prettier,
      toml = { 'taplo' },
      c = { 'clang-format' },
      cpp = { 'clang-format' },
      ['_'] = { 'trim_whitespace', 'trim_newlines' },
    }

    -- Herramientas que no vienen de Mason: se activan solo si existen
    if exe('rustfmt') then
      formatters_by_ft.rust = { 'rustfmt' }
    end
    if exe('alejandra') then
      formatters_by_ft.nix = { 'alejandra' }
    end
    if exe('gofumpt') then
      formatters_by_ft.go = { 'gofumpt', 'goimports-reviser' }
    end

    require('conform').setup({
      format_on_save = function(bufnr)
        -- Flag global (:FormatToggle) + flag por buffer, como craftzdog:
        -- permite desactivar el autoformato solo en un archivo puntual.
        if vim.g.autoformat_enabled == false or vim.b[bufnr].disable_autoformat then
          return
        end
        -- lsp_fallback = false porque plugins/lsp/format.lua desactiva las
        -- capacidades de formato del LSP: el fallback nunca iba a disparar.
        return { timeout_ms = 1000, lsp_fallback = false }
      end,
      max_file_size = 200 * 1024,
      formatters_by_ft = formatters_by_ft,
      formatters = {
        oxfmt = {
          condition = has_oxfmtrc,
        },
        eslint_d = {
          condition = has_eslintrc,
          cwd = require('conform.util').root_file({
            'package.json',
            'eslint.config.js',
            '.eslintrc',
            '.eslintrc.js',
            '.eslintrc.json',
          }),
        },
        prettier = {
          cwd = require('conform.util').root_file({
            '.prettierrc',
            'prettier.config.js',
            'package.json',
          }),
        },
        shfmt = {
          prepend_args = { '-i', '2', '-ci' },
        },
      },
    })

    vim.g.autoformat_enabled = vim.g.autoformat_enabled ~= false
    vim.api.nvim_create_user_command('FormatToggle', function()
      vim.g.autoformat_enabled = not vim.g.autoformat_enabled
      vim.notify('Format on Save: ' .. (vim.g.autoformat_enabled and 'ON' or 'OFF'))
    end, {})
  end,
}

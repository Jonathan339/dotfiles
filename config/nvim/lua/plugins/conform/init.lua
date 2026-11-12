-- lua/plugins/conform/init.lua

local oxfmtrc_files = {
  '.oxfmtrc.json',
  '.oxfmtrc.jsonc',
  'oxfmt.config.ts',
}

local function has_oxfmtrc(bufnr)
  return vim.fs.root(bufnr, oxfmtrc_files) ~= nil
end

local function exe(name)
  return vim.fn.executable(name) == 1
end

-- Oxfmt solo se usa si el proyecto tiene config de Oxc y el binario existe.
-- En cualquier otro caso se usa Prettier, sin encadenar formateadores.
local function oxfmt_available(bufnr)
  return has_oxfmtrc(bufnr) and require('conform').get_formatter_info('oxfmt', bufnr).available
end

local function js_formatters(bufnr)
  return { oxfmt_available(bufnr) and 'oxfmt' or 'prettier' }
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
      vue = { 'prettier' },
      svelte = { 'prettier' },
      astro = { 'prettier' },
      lua = { 'stylua' },
      python = { 'ruff_organize_imports', 'ruff_format' },
      sh = { 'shfmt' },
      json = { 'prettier' },
      jsonc = { 'prettier' },
      yaml = { 'prettier' },
      markdown = { 'prettier' },
      css = { 'prettier' },
      scss = { 'prettier' },
      less = { 'prettier' },
      html = { 'prettier' },
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
        -- Misma política de archivos grandes que config/autocmd.lua.
        if vim.b[bufnr].large_file then
          return
        end
        -- lsp_fallback = false porque plugins/lsp/format.lua desactiva las
        -- capacidades de formato del LSP: el fallback nunca iba a disparar.
        return { timeout_ms = 1000, lsp_fallback = false }
      end,
      formatters_by_ft = formatters_by_ft,
      formatters = {
        oxfmt = {
          condition = function(_, ctx)
            return ctx and ctx.buf and has_oxfmtrc(ctx.buf) or false
          end,
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

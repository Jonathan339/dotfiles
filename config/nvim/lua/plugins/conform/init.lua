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

local function has_eslintrc(ctx)
  if not ctx or not ctx.buf then
    return false
  end
  local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.buf), ':h')
  if dir == '' then
    return false
  end
  for _, f in ipairs(eslintrc_files) do
    if vim.fn.findfile(f, dir .. ';') ~= '' then
      return true
    end
  end
  return false
end

local function exe(name)
  return vim.fn.executable(name) == 1
end

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo', 'Format', 'FormatToggle' },
  config = function()
    -- Filetypes reales de Neovim (jsx/tsx == javascriptreact/typescriptreact)
    local formatters_by_ft = {
      javascript = { 'eslint_d', 'prettier' },
      javascriptreact = { 'eslint_d', 'prettier' },
      typescript = { 'eslint_d', 'prettier' },
      typescriptreact = { 'eslint_d', 'prettier' },
      vue = { 'eslint_d', 'prettier' },
      svelte = { 'eslint_d', 'prettier' },
      astro = { 'eslint_d', 'prettier' },
      lua = { 'stylua' },
      python = { 'ruff_organize_imports', 'ruff_format' },
      sh = { 'shfmt' },
      json = { 'prettier' },
      jsonc = { 'prettier' },
      yaml = { 'prettier' },
      markdown = { 'prettier' },
      css = { 'prettier' },
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
      format_on_save = function()
        if vim.g.autoformat_enabled == false then
          return
        end
        -- lsp_fallback = false porque plugins/lsp/format.lua desactiva las
        -- capacidades de formato del LSP: el fallback nunca iba a disparar.
        return { timeout_ms = 1000, lsp_fallback = false }
      end,
      max_file_size = 200 * 1024,
      formatters_by_ft = formatters_by_ft,
      formatters = {
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

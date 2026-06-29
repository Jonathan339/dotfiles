local eslintrc_files = {
  '.eslintrc', '.eslintrc.cjs', '.eslintrc.js',
  '.eslintrc.json', '.eslintrc.yaml', '.eslintrc.yml',
  'eslint.config.js', 'eslint.config.cjs',
  'eslint.config.mjs', 'eslint.config.ts',
}

local function has_eslintrc(ctx)
  if not ctx or not ctx.buf then return false end
  local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.buf), ':h')
  if dir == '' then return false end
  for _, f in ipairs(eslintrc_files) do
    if vim.fn.findfile(f, dir .. ';') ~= '' then return true end
  end
  return false
end

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo', 'Format', 'FormatToggle' },
  config = function()
    require('conform').setup({
      format_on_save = function(bufnr)
        if vim.g.autoformat_enabled == false then return end
        return { timeout_ms = 1000, lsp_fallback = true }
      end,
      max_file_size = 200 * 1024,
      formatters_by_ft = {
        javascript = { 'eslint_d', 'prettier' },
        javascriptreact = { 'eslint_d', 'prettier' },
        typescript = { 'eslint_d', 'prettier' },
        typescriptreact = { 'eslint_d', 'prettier' },
        jsx = { 'eslint_d', 'prettier' },
        tsx = { 'eslint_d', 'prettier' },
        vue = { 'eslint_d', 'prettier' },
        svelte = { 'eslint_d', 'prettier' },
        astro = { 'eslint_d', 'prettier' },
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        sh = { 'shfmt' },
        json = { 'prettier' },
        yaml = { 'prettier' },
        markdown = { 'prettier' },
        css = { 'prettier' },
        html = { 'prettier' },
        toml = { 'taplo' },
        nix = { 'alejandra' },
        go = { 'gofumpt', 'goimports-reviser' },
        c = { 'clang-format' },
        cpp = { 'clang-format' },
        rust = { 'rustfmt' },
        ['_'] = { 'trim_whitespace', 'trim_newlines' },
      },
      formatters = {
        eslint_d = {
          condition = has_eslintrc,
          cwd = require('conform.util').root_file_name({
            'package.json', 'eslint.config.js', '.eslintrc', '.eslintrc.js', '.eslintrc.json',
          }),
        },
        prettier = {
          cwd = require('conform.util').root_file_name({
            '.prettierrc', 'prettier.config.js', 'package.json',
          }),
        },
        black = {
          cwd = require('conform.util').root_file_name({
            'pyproject.toml', 'requirements.txt', 'poetry.lock',
          }),
        },
        isort = {
          cwd = require('conform.util').root_file_name({
            'pyproject.toml', 'requirements.txt', 'poetry.lock',
          }),
        },
        shfmt = {
          prepend_args = { '-i', '2', '-ci' },
        },
      },
    })

    local format_enabled = true
    vim.api.nvim_create_user_command('Format', function()
      require('conform').format({ lsp_fallback = true })
    end, {})
    vim.api.nvim_create_user_command('FormatToggle', function()
      format_enabled = not format_enabled
      vim.g.autoformat_enabled = format_enabled
      vim.notify('Format on Save: ' .. (format_enabled and 'ON' or 'OFF'))
    end, {})
  end,
}

local function root_file_condition(files)
  return function(ctx)
    if not ctx or not ctx.buf then return false end
    local dir = vim.api.nvim_buf_get_name(ctx.buf)
    if dir == '' then return false end
    dir = vim.fn.fnamemodify(dir, ':h')
    for _, f in ipairs(files) do
      if vim.fn.findfile(f, dir .. ';') ~= '' then return true end
    end
    return false
  end
end

local function root_dir_fn(files)
  return function(ctx)
    if not ctx or not ctx.buf then return nil end
    local dir = vim.api.nvim_buf_get_name(ctx.buf)
    if dir == '' then return nil end
    dir = vim.fn.fnamemodify(dir, ':h')
    for _, f in ipairs(files) do
      local found = vim.fn.findfile(f, dir .. ';')
      if found ~= '' then return vim.fn.fnamemodify(found, ':p:h') end
    end
    return vim.fn.getcwd()
  end
end

return {
  dir = vim.fn.stdpath('config'),
  name = 'auto-ensure',
  lazy = false,
  dependencies = { 'stevearc/conform.nvim' },
  config = function()
    local eslintrc = {
      '.eslintrc', '.eslintrc.cjs', '.eslintrc.js',
      '.eslintrc.json', '.eslintrc.yaml', '.eslintrc.yml',
      'eslint.config.js', 'eslint.config.cjs',
      'eslint.config.mjs', 'eslint.config.ts',
    }
    local prettierrc = { '.prettierrc', 'prettier.config.js', 'package.json' }
    local pyproject = { 'pyproject.toml', 'requirements.txt', 'poetry.lock' }
    local eslint_cwd = { 'package.json', 'eslint.config.js', '.eslintrc', '.eslintrc.js', '.eslintrc.json' }

    require('auto_ensure').setup({
      formatters = {
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
            condition = root_file_condition(eslintrc),
            cwd = root_dir_fn(eslint_cwd),
          },
          prettier = {
            cwd = root_dir_fn(prettierrc),
          },
          black = {
            cwd = root_dir_fn(pyproject),
          },
          isort = {
            cwd = root_dir_fn(pyproject),
          },
          shfmt = {
            prepend_args = { '-i', '2', '-ci' },
          },
        },
        max_format_size = 200 * 1024,
      },
    })
  end,
}

return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufWritePost" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      zsh = { "shellcheck" },
      markdown = { "markdownlint" },
      yaml = { "yamllint" },
      python = { "ruff" },
      go = { "staticcheck" },
      lua = { "luacheck" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

  end,
}

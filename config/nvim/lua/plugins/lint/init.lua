return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufWritePost" },
  config = function()
    local lint = require("lint")

    local available_by_ft = {
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      zsh = { "shellcheck" },
      markdown = { "markdownlint" },
      yaml = { "yamllint" },
      python = { "ruff" },
      go = { "staticcheck" },
      lua = { "luacheck" },
    }
    lint.linters_by_ft = {}
    for ft, linters in pairs(available_by_ft) do
      local ready = {}
      for _, linter in ipairs(linters) do
        if vim.fn.executable(linter) == 1 then
          table.insert(ready, linter)
        end
      end
      if #ready > 0 then
        lint.linters_by_ft[ft] = ready
      end
    end

    local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

  end,
}

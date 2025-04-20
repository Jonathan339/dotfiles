-- https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki

local M = {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "echasnovski/mini.nvim", 'nvim-tree/nvim-web-devicons'
  },
  ft = { "markdown", "quarto" },
}

M.config = function()
  require("render-markdown").setup({
    anti_conceal = {
      enabled = true,
      -- Which elements to always show, ignoring anti conceal behavior. Values can either be booleans
      -- to fix the behavior or string lists representing modes where anti conceal behavior will be
      -- ignored. Possible keys are:
      --  head_icon, head_background, head_border, code_language, code_background, code_border
      --  dash, bullet, check_icon, check_scope, quote, table_border, callout, link, sign
      ignore = {
        code_background = true,
        sign = true,
      },
      above = 0,
      below = 0,
    },
    render_modes = true,
    heading = {
      enabled = true,
      sign = true,
      style = "full",
      icons = { "① ", "② ", "③ ", "④ ", "⑤ ", "⑥ " },
      left_pad = 1,
    },
    bullet = {
      enabled = true,
      icons = { "●", "○", "◆", "◇" },
      right_pad = 1,
      highlight = "render-markdownBullet",
    },
  })
end

return M

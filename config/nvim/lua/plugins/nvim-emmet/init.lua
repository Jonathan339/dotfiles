return {
  {
    "olrtg/nvim-emmet",
    ft = { 'html', 'xml', 'jsx', 'tsx', 'svelte', 'vue', 'astro' },
    config = function()
      vim.keymap.set("i", "<CR>", function()
        local emmet = require("nvim-emmet")

        if emmet.is_expandable() then
          emmet.expand_abbreviation()
          return ""
        end

        return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
      end, { expr = true, silent = true })
    end,
  },
}

return {
  {
    "olrtg/nvim-emmet",
    ft = { 'html', 'xml', 'jsx', 'tsx', 'svelte', 'vue', 'astro' },
    config = function()
      vim.keymap.set("i", "<CR>", function()
        -- si el menú de cmp está abierto, primero confirmamos el completado:
        -- sin esto emmet se come el <CR> en html/tsx/vue/etc.
        local ok_cmp, cmp = pcall(require, "cmp")
        if ok_cmp and cmp.visible() then
          local entry = cmp.get_selected_entry()
            or { get_insert_text = function() return nil end }
          cmp.confirm(entry, { select = false })
          return ""
        end

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

return {
  'folke/which-key.nvim',
  event = 'VeryLazy', -- que se instale/cargue sí o sí
  opts = {
    preset = 'classic',
    win = { border = 'rounded' },
    spec = {
      -- Solo los prefijos que agrupan varios keymaps. Los mapeos directos
      -- (f, b, h, l, t, m, n…) los muestra which-key por sí solo.
      { '<leader>s', group = 'Splits' },
      { '<leader>u', group = 'UI y notificaciones' },
      { '<leader>a', group = 'Auto Save' },
    },
  },
}

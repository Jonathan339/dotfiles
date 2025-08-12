---@diagnostic disable: undefined-global
return {
  'brenoprata10/nvim-highlight-colors',
  event = { 'BufReadPost', 'InsertEnter' },
  opts = function()
    return {
      render = 'background', -- "background" | "foreground" | "first_column" | "virtual"
      enable_hex = true,
      enable_rgb = true,
      enable_hsl = true,
      enable_var_usage = true, -- CSS variables (--color)
      enable_named_colors = true, -- red, blue, etc.
      custom_colors = {
        { label = '%-%-theme%-primary%-color', color = '#0f1219' },
        { label = '%-%-theme%-secondary%-color', color = '#5a5d64' },
      },
      exclude_filetypes = {
        'help',
        'lazy',
        'mason',
        'TelescopePrompt',
        'neo-tree',
        'oil',
        'qf',
        'notify',
        'noice',
      },
      exclude_buftypes = { 'nofile', 'prompt', 'terminal' },
    }
  end,
  config = function(_, opts)
    -- No lo actives en archivos marcados como grandes
    if vim.b.large_file then
      return
    end
    require('nvim-highlight-colors').setup(opts)
  end,
}

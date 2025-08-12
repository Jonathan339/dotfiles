local M = {
  "windwp/nvim-ts-autotag",
  ft = {
    "html", "xml",
    "javascript", "typescript", "jsx", "tsx",
    "javascriptreact", "typescriptreact",
    "vue", "svelte", "astro",
    "heex", "eex", "php", "rescript",
    "glimmer", "handlebars", "hbs", "ejs",
  },
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
}

M.config = function()
  require("nvim-ts-autotag").setup({
    -- opciones globales
    opts = {
      enable_close = true,
      enable_rename = true,
      enable_close_on_slash = true,
    },
    -- overrides por filetype
    per_filetype = {
      html = { enable_close = true, enable_rename = true },
      xml  = { enable_close = true },
      tsx  = { enable_close = true, enable_rename = true, enable_close_on_slash = true },
      jsx  = { enable_close = true, enable_rename = true, enable_close_on_slash = true },

      typescriptreact  = { enable_close = true, enable_rename = true },
      javascriptreact  = { enable_close = true, enable_rename = true },
      vue   = { enable_close = true, enable_rename = true },
      svelte= { enable_close = true, enable_rename = true },
      astro = { enable_close = true, enable_rename = true },

      heex  = { enable_close = true },
      eex   = { enable_close = true },
      php   = { enable_close = true },
      rescript = { enable_close = true },

      glimmer = { enable_close = true },
      handlebars = { enable_close = true },
      hbs = { enable_close = true },
      ejs = { enable_close = true },
    },
  })
end

return M

local user_config = require("config.user")
local u = require("utils")

return {
  "L3MON4D3/LuaSnip",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  config = function()
    local ls = require("luasnip")
    ls.config.set_config(u.merge({
      history = true,
      updateevents = "TextChanged,TextChangedI",
      enable_autosnippets = true,
    }, user_config.plugins and user_config.plugins.luasnip or {}))

    -- Extender snippets de HTML a archivos de React
    ls.filetype_extend("javascriptreact", { "html" })
    ls.filetype_extend("typescriptreact", { "html" })

    -- Cargar snippets de friendly-snippets
    require("luasnip.loaders.from_vscode").lazy_load()

    -- Función para cargar snippets personalizados
    local function cargar_snippets()
      for _, ft_path in ipairs(vim.api.nvim_get_runtime_file("lua/plugins/luasnip/snippets/*.lua", true)) do
        local status, err = pcall(dofile, ft_path)
        if not status then
          vim.notify("Error al cargar el snippet: " .. err, vim.log.levels.ERROR)
        end
      end
    end

    -- Ejecutar la carga de snippets personalizados
    cargar_snippets()
  end,

  enabled = not vim.tbl_contains(user_config.disable_builtin_plugins, "luasnip"),
}

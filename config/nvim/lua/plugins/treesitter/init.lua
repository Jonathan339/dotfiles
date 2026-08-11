return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,

  init = function()

    ---------------------------------------------------------------
    -- 1. Asegurar tree-sitter CLI con bun
    ---------------------------------------------------------------
    local function ensure_tree_sitter_cli(callback)
      if vim.fn.executable("tree-sitter") == 1 then
        callback()
        return
      end

      if vim.fn.executable("bun") == 0 then
        vim.notify(
          "tree-sitter no encontrado y bun no está instalado",
          vim.log.levels.WARN
        )
        return
      end

      vim.notify("Instalando tree-sitter-cli con bun...", vim.log.levels.INFO)

      vim.system(
        { "bun", "install", "-g", "tree-sitter-cli" },
        { text = true },
        function(obj)
          if obj.code ~= 0 then
            vim.schedule(function()
              vim.notify(
                "Error instalando tree-sitter-cli con bun",
                vim.log.levels.ERROR
              )
            end)
            return
          end

          vim.schedule(function()
            if vim.fn.executable("tree-sitter") == 1 then
              vim.notify("tree-sitter-cli instalado correctamente", vim.log.levels.INFO)
              callback()
            else
              vim.notify(
                "tree-sitter se instaló pero no está en PATH",
                vim.log.levels.ERROR
              )
            end
          end)
        end
      )
    end

    ---------------------------------------------------------------
    -- 2. Instalar parsers faltantes
    ---------------------------------------------------------------
    local function ensure_parsers()
      local ensure_installed = {
        "vim", "regex", "rust", "markdown", "json",
        "javascript", "typescript", "tsx",
        "yaml", "html", "css", "bash", "lua", "dockerfile",
        "solidity", "gitignore", "python",
        "vue", "svelte", "toml", "go",
      }

      require("nvim-treesitter").install(ensure_installed)
    end

    ---------------------------------------------------------------
    -- 3. Ejecutar todo en orden correcto
    ---------------------------------------------------------------
    ensure_tree_sitter_cli(function()
      ensure_parsers()
    end)

  end,
}

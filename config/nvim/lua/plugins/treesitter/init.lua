local NVIM_DIR = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")

local function tree_sitter_path()
  local local_path = NVIM_DIR .. "/node_modules/.bin/tree-sitter"
  if vim.fn.executable(local_path) == 1 then
    return local_path
  end
  if vim.fn.executable("tree-sitter") == 1 then
    return "tree-sitter"
  end
  return nil
end

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

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  event = { "BufReadPre", "BufNewFile" },

  init = function()
    if tree_sitter_path() then
      ensure_parsers()
      return
    end

    if vim.fn.executable("bun") == 0 then
      vim.notify("tree-sitter no encontrado y bun no está instalado", vim.log.levels.WARN)
      return
    end

    vim.notify("Instalando tree-sitter-cli local con bun...", vim.log.levels.INFO)

    vim.system(
      { "bun", "install" },
      { text = true, cwd = NVIM_DIR },
      function(obj)
        if obj.code ~= 0 then
          vim.schedule(function()
            vim.notify("Error instalando tree-sitter-cli local", vim.log.levels.ERROR)
          end)
          return
        end

        vim.schedule(function()
          if tree_sitter_path() then
            vim.notify("tree-sitter-cli instalado localmente", vim.log.levels.INFO)
            ensure_parsers()
          else
            vim.notify("tree-sitter se instaló pero no está en node_modules/.bin", vim.log.levels.ERROR)
          end
        end)
      end
    )
  end,
}

local M = {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  -- Cambiado a event = "VeryLazy" para que las extensiones y comandos clave
  -- estén listos en segundo plano sin ralentizar el arranque inicial de Neovim
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-live-grep-args.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
  },
}

M.config = function()
  local telescope = require("telescope")
  local actions = require("telescope.actions")
  local lga_actions = require("telescope-live-grep-args.actions")

  -- Cacheamos variables globales de uso frecuente dentro de la config
  local math_floor = math.floor

  telescope.setup({
    defaults = {
      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--hidden",
        "--glob",
        "!.git/*",
      },
      file_ignore_patterns = { "node_modules", "%.git/", "dist/", "build/" },
      prompt_prefix = " ❯ ", -- Un espacio extra para que no pegue el texto al borde
      selection_caret = "❯ ",
      layout_strategy = "horizontal",
      layout_config = {
        width = 0.95,
        height = 0.85,
        prompt_position = "bottom",
        horizontal = {
          preview_width = function(_, cols)
            return math_floor(cols * (cols > 200 and 0.5 or 0.7))
          end,
        },
      },
      sorting_strategy = "descending",
      scroll_strategy = "cycle",
      mappings = {
        i = {
          ["<C-n>"] = actions.move_selection_next,
          ["<C-p>"] = actions.move_selection_previous,
          ["<C-c>"] = actions.close, -- Atajo rápido para cerrar sin estirar la mano al Esc
        },
      },
    },

    pickers = {
      find_files = {
        find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
      },
    },

    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },

      live_grep_args = {
        auto_quoting = true,
        mappings = {
          i = {
            ["<C-k>"] = lga_actions.quote_prompt(),
            ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
          },
        },
      },

      file_browser = {
        grouped = true,
        hijack_netrw = true,
        hidden = true,
      },
    },
  })

  -- Carga optimizada de extensiones
  telescope.load_extension("fzf")
  telescope.load_extension("file_browser")
  telescope.load_extension("live_grep_args")
end

return M

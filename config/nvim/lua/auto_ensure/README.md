# auto-ensure.nvim

Instala paquetes Mason por filetype y configura formateo con conform.nvim, todo bajo demanda.

## Requisitos

- Neovim >= 0.9
- [mason.nvim](https://github.com/williamboman/mason.nvim)
- [conform.nvim](https://github.com/stevearc/conform.nvim)

## Instalación

### Como plugin publicado (GitHub)

```lua
{
  'tu-usuario/auto-ensure.nvim',
  lazy = false,
  dependencies = {
    'williamboman/mason.nvim',
    'stevearc/conform.nvim',
  },
  opts = {
    ensure_installed = {
      lua = { 'stylua' },
      javascript = { 'eslint_d', 'prettierd', 'prettier' },
    },
    formatters = {
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'eslint_d', 'prettierd', 'prettier' },
        ['_'] = { 'trim_whitespace', 'trim_newlines' },
      },
    },
  },
}
```

Con `opts`, lazy.nvim pasa la tabla a `require('auto-ensure').setup(opts)` automáticamente.

### Como plugin local (dotfiles)

```lua
{
  dir = vim.fn.stdpath('config'),
  name = 'auto-ensure',
  lazy = false,
  dependencies = { 'stevearc/conform.nvim' },
  config = function()
    require('auto_ensure').setup({
      -- tu config
    })
  end,
}
```

## Ejemplos de configuración

### Solo instalación (sin formateo)

```lua
require('auto_ensure').setup({
  ensure_installed = {
    python = { 'black', 'isort', 'ruff' },
    lua = { 'stylua' },
    go = { 'gofumpt', 'goimports-reviser' },
    rust = { 'rustfmt' },
  },
  -- omitís formatters → no toca conform.nvim
})
```

### Solo formateo (sin instalación Mason)

```lua
require('auto_ensure').setup({
  formatters = {
    formatters_by_ft = {
      python = { 'isort', 'black' },
      lua = { 'stylua' },
    },
    formatters = {
      black = {
        cwd = require('conform.util').root_file({ 'pyproject.toml', 'requirements.txt' }),
      },
    },
    format_on_save = true,
    max_format_size = 500 * 1024,
  },
})
```

### Completo con conditions y root_dir

```lua
local function has_root_file(files)
  return function(ctx)
    if not ctx or not ctx.buf then return false end
    local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.buf), ':h')
    for _, f in ipairs(files) do
      if vim.fn.findfile(f, dir .. ';') ~= '' then return true end
    end
    return false
  end
end

local function root_dir(files)
  return function(ctx)
    if not ctx or not ctx.buf then return nil end
    local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.buf), ':h')
    for _, f in ipairs(files) do
      local found = vim.fn.findfile(f, dir .. ';')
      if found ~= '' then return vim.fn.fnamemodify(found, ':p:h') end
    end
    return vim.fn.getcwd()
  end
end

require('auto_ensure').setup({
  ensure_installed = {
    javascript = { 'eslint_d', 'prettierd', 'prettier' },
    typescript = { 'eslint_d', 'prettierd', 'prettier' },
  },
  formatters = {
    formatters_by_ft = {
      javascript = { 'eslint_d', 'prettierd', 'prettier' },
      typescript = { 'eslint_d', 'prettierd', 'prettier' },
      ['_'] = { 'trim_whitespace', 'trim_newlines' },
    },
    formatters = {
      eslint_d = {
        condition = has_root_file({
          '.eslintrc', 'eslint.config.js',
        }),
        cwd = root_dir({
          'package.json', '.eslintrc', 'eslint.config.js',
        }),
      },
      prettierd = {
        cwd = root_dir({ '.prettierrc', 'prettier.config.js', 'package.json' }),
      },
    },
    max_format_size = 200 * 1024,
  },
})
```

### Skip personalizados

```lua
require('auto_ensure').setup({
  ensure_installed = { go = { 'gofumpt', 'goimports-reviser' } },
  skip_fts = { 'help', 'qf', 'neo-tree', 'TelescopePrompt', 'gitcommit' },
  max_file_size = 0,        -- 0 desactiva el límite de tamaño
  log_level = vim.log.levels.WARN, -- menos ruido
})
```

## Opciones

| Campo | Tipo | Default | Descripción |
|-------|------|---------|-------------|
| `ensure_installed` | `table<string, string[]>` | `{}` | filetype → lista de paquetes Mason |
| `skip_fts` | `string[]` | ver abajo | filetypes a ignorar |
| `max_file_size` | `number` | `1048576` (1 MB) | archivos más grandes se saltan |
| `log_level` | `number` | `vim.log.levels.INFO` | nivel de log |
| `formatters` | `table` o `nil` | `nil` | configuración de conform.nvim |

### skip_fts por defecto

`gitcommit`, `gitrebase`, `help`, `TelescopePrompt`, `neo-tree`, `oil`, `dirvish`, `alpha`, `startify`, `qf`

## Formateo

Si pasás `formatters`, el plugin:

1. Llama a `conform.setup()` con tu config
2. Registra un autocomando `BufWritePre` para formatear al guardar
3. Activa `lsp_fallback` si ningún formatter matchea

### Comandos

- `:Format` — formatea el buffer actual
- `:FormatToggle` — activa/desactiva formato al guardar

## Instalación bajo demanda

Escucha el evento `FileType`. Cuando ves un tipo de archivo nuevo, instala los paquetes Mason correspondientes con una cola serializada.

### Comandos

- `:AutoEnsureHere` — re-ejecuta ensure para el filetype del buffer actual
- `:AutoEnsurePurgeVisited` — limpia el cache de filetypes ya procesados
- `:AutoEnsureAllKnown` — encola instalación para todos los filetypes configurados

## Estructura del plugin

```
auto-ensure.nvim/
├── lua/
│   └── auto_ensure/
│       └── init.lua       -- core: setup, cola, Mason, formateo
└── README.md
```

Solo necesitás un archivo: `lua/auto_ensure/init.lua`. El resto (spec de lazy.nvim con defaults) es decisión del usuario.

## Publicar

1. Creá un repo en GitHub con `lua/auto_ensure/init.lua` y este README
2. La gente lo instala con lazy.nvim via `'tu-usuario/auto-ensure.nvim'` + `opts`
3. Mason y conform se declaran como `dependencies` en la spec

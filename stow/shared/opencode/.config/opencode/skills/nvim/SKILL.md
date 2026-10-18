---
name: nvim
description: "Config de Neovim (lazy.nvim modular en ~/.dotfiles/config/nvim): estructura, agregar plugins, keymaps, snippets, lockfiles y updates. Usar al editar, extender o diagnosticar la configuración de Neovim."
---

# Neovim — config modular (lazy.nvim)

Archivo real: `~/.dotfiles/config/nvim` (stow lo linkea a `~/.config/nvim`). Editar siempre desde el repo y commitear (convención del skill `git`).

## Estructura

```
init.lua                 → require('config')
lua/config/
  init.lua               → punto de entrada del grupo (option/map/autocmd/lazy)
  lazy.lua               → bootstrap y setup de lazy.nvim
  option.lua             → opciones
  map.lua                → keymaps globales
  autocmd.lua            → autocomandos
lua/plugins/
  <plugin>/init.lua      → un módulo por plugin (spec de lazy.nvim)
  lsp/                   → defaults, format, handlers, init
  luasnip/snippets/      → snippets por lenguaje
lua/utils/               → helpers (iconos, etc.)
```

## Agregar un plugin

1. Crear `lua/plugins/<nombre>/init.lua` que **devuelva** la spec de lazy.nvim: `return { 'owner/repo', event = ..., keys = ..., opts = { ... } }`.
2. Probar en nvim: `:Lazy` (aparece en la lista), `:Lazy sync` si falta instalar.
3. Si cambió `lazy-lock.json`, commitearlo junto con el plugin (está versionado a propósito).
4. Si el plugin arrastra dependencias JS/Node (ej. `tree-sitter-cli`), revisar `package.json` y `bun.lock` (también versionados).

## Mantenimiento

- Actualizar: `:Lazy sync` (o `:Lazy update`) y commitear el lockfile actualizado.
- Diagnóstico: `:Lazy health`, `:checkhealth`.
- LSP, formato y lint viven en `lua/plugins/lsp/`, `lua/plugins/conform/` y `lua/plugins/lint/`: tocar ahí, no en otro lado.
- No borres ni regeneres a mano `lazy-lock.json`, `package.json` ni `bun.lock`.

## Convenciones

- Un módulo por plugin, nombre en kebab-case igual que el plugin.
- Commits: `feat(nvim): ...`, `fix(nvim): ...`, `chore(nvim): ...`.

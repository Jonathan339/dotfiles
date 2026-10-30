---
name: opencode-local
description: "Setup local de OpenCode: layout del config, plugins/agents instalados, declaración de MCP y receta de reconexión ante `client exact-build admission failed`. Usar al tocar la config de OpenCode, diagnosticar MCP o revisar logs."
---

# OpenCode local — setup y troubleshooting

Para la documentación general de OpenCode está el skill builtin `opencode`; acá va solo lo de esta máquina.

## Layout de `~/.config/opencode`

Directorio real (no symlink) con mezcla de archivos del repo y cosas locales:

| Entrada | Origen |
|---|---|
| `AGENTS.md`, `opencode.json`, `opencode.jsonc`, `package.json`, `package-lock.json`, `plugins/` | symlinks al repo (`~/.dotfiles/stow/shared/opencode/.config/opencode/`) |
| `skills/` | directorio real: `codebase-memory` (instalador CBM) + nuestros skills linkeados (git, dotfiles, paleta, nvim, cachyos) |
| `agents/` | real, del instalador CBM: `codebase-memory`, `codebase-memory-scout`, `codebase-memory-auditor` |
| `service.json` | local, 0600, credenciales del servicio — **no tocar, no exponer, no commitear** |

Editar la config = editar el archivo real en `stow/…` (el paquete `opencode` guarda los archivos reales ahí, no en `config/`) y commitear con convención (skill `git`).

## Config actual

- `opencode.json`: provider `ollama` con **solo overrides** (`capabilities` + `limit` 8192/4096) para `qwen3.5:9b`, `qwen3.5:4b`, `gemma4:12b` y `deepseek-r1:latest` (este último con `tools: false`: Ollama no le inyecta herramientas); `mcp.codebase-memory-mcp` (local, binario `~/.local/bin/codebase-memory-mcp`), `mcp.servers.context7` (remoto), `permission: "allow"`.
- **Ollama se autodescubre en V2**: OpenCode sondea `127.0.0.1:11434` y agrega los modelos con capability `completion` sin declarar `settings.baseURL`. Por eso el `providers` solo lleva los overrides.
- **`llamacpp` no se autodescubre**: se declara con `package: "@opencode/ai/providers/openai-compatible"` y `settings.baseURL: "http://127.0.0.1:8080/v1"` (servidor de llama.cpp, ver skill `ia-local`). El modelo `qwen3.5-9b` lleva `limit` 24576/4096 y `tools: true`. Como es declarado, aparece en el picker aunque el server esté caído: ahí falla al usarlo, no al listarlo. Verificación: `opencode api --standalone get /api/model | jq '.data[] | select(.providerID=="llamacpp")'`.
- **Por qué se declaran los límites**: el modelo descubierto hereda el ctx máximo del modelo (p.ej. `deepseek-r1:latest` → 131072), no el cap real del servicio (`OLLAMA_CONTEXT_LENGTH=8192`). Sin el override OpenCode presupuesta 128k y rompe en sesiones largas.
- Verificar la config sin reiniciar el servicio: `opencode api --standalone get /api/model` (server privado, no corta la sesión) y filtrar por `providerID=="ollama"`.
- Tras editar `opencode.json` sí hace falta `opencode service restart` para que el servicio compartido recargue.
- `opencode.jsonc`: `shell: /bin/zsh` + la **misma** declaración de `codebase-memory-mcp`.
- Rareza conocida: el MCP está declarado **dos veces** (en ambos archivos). Consolidación pendiente: dejar una sola declaración, preferentemente bajo `mcp.servers`.
- Plugins: `cbm-augment.ts` (instalador CBM, `hook-augment`).

## Receta: MCP en `failed` con "client exact-build admission failed"

**Causa**: la activación post-install/update de codebase-memory-mcp detiene el daemon y lo reemplaza durante unos segundos (~10 s). Si OpenCode arranca el server justo en esa ventana, la admisión exact-build lo rechaza y OpenCode **no reintenta**: queda en `failed` hasta que algo lo reconecte.

**Fix sin tocar config** (reconectar):

```sh
opencode api post '/api/experimental/mcp/codebase-memory-mcp/connect'
# para otro proyecto/directorio:
opencode api post '/api/experimental/mcp/codebase-memory-mcp/connect?location[directory]=/ruta/del/proyecto'
```

**Verificar**: `opencode mcp list` → debe mostrar `✓ connected`.

**Evidencia / logs**:

- `~/.local/share/opencode/log/opencode.log` — arranque del MCP y errores de admisión.
- `~/.cache/codebase-memory-mcp/logs/activation-events.ndjson` — ventana de activación (requested / daemon_stopped / completed).

**Fallback**: `opencode service restart` (o `/mcps` en la TUI). Tras cada update de CBM, asumir que puede repetirse.

## Otros chequeos útiles

- `opencode service status` y `opencode api get /api/info` — salud del servicio.
- La config de MCP vive bajo `mcp` (V2: `mcp.servers`); no inventar campos: el schema es `https://opencode.ai/config.json`.
- El bloque de codebase-memory en `AGENTS.md` se auto-regenera con cada update del instalador: no editarlo a mano.

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

- `opencode.json`: un solo provider, `llamacpp-coder` (`package: "@opencode/ai/providers/openai-compatible"`, `settings.baseURL: "http://127.0.0.1:8082/v1"`) con el modelo `qwen2.5-coder-7b` (`limit` 32768/4096, `tools: true`), que es además el `model` por defecto. Además `mcp.servers` (codebase-memory-mcp, context7, playwright, browserbase deshabilitado), `permission: "allow"` y `shell: /bin/zsh`.
- **`llamacpp` no se autodescubre**: cada server de llama.cpp se declara a mano con `package: "@opencode/ai/providers/openai-compatible"` + su `baseURL` (un `baseURL` por provider, por eso cada puerto necesita su propia entrada). Como es declarado, aparece en el picker aunque el server esté caído: ahí falla al usarlo, no al listarlo. Verificación: `opencode api --standalone get /api/model | jq '.data[] | select(.providerID|test("llamacpp"))'`.
- **Por qué se declaran los límites**: un modelo autodescubierto hereda el ctx máximo entrenado (`n_ctx_train`, acá 131072), no el `--ctx-size` real del server. Sin el override OpenCode presupuesta 128k y rompe en sesiones largas. En este server `--ctx-size` es 32768 → `limit.context: 32768`.
- Verificar la config sin reiniciar el servicio: `opencode api --standalone get /api/model` (server privado, no corta la sesión).
- **Pendiente: Ollama vuelve.** Se desinstaló y quedó fuera de `providers` (01/11/2026), pero Jonathan va a reinstalarlo. Cuando esté: OpenCode lo autodescubre en `127.0.0.1:11434` (agrega los modelos con capability `completion`, sin `settings.baseURL`) y hay que re-agregar los overrides `capabilities` + `limit` 32768/4096 en `providers.ollama.models` para los modelos que use, verificando tools reales (ver skill `ia-local`).
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

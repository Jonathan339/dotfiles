---
name: ia-local
description: "IA local de esta máquina (Ollama sobre Intel Arc B570 vía Vulkan): inventario, configuración esperada del servicio, reparto de VRAM, velocidades de referencia y diagnóstico de regresiones. Usar al preguntar qué IA local corre, si Ollama está bien configurado, por qué un modelo va lento o cae a CPU, agregar o quitar modelos, o tocar cualquier config de IA local."
---

# IA local — Ollama sobre Intel Arc B570

Para lo general de OpenCode está el skill `opencode-local`; acá va la IA local de esta máquina.

## Verificación en un comando

```sh
make ia          # desde ~/.dotfiles: inventario, config, GPU y opencode (solo lectura)
make ia-bench    # ídem + mide tok/s del modelo cargado (~15-40 s, carga el modelo)

~/.dotfiles/scripts/ollama-check.sh --bench gemma4:12b   # medir un modelo puntual
```

Esperado: `0 error(es)`. Un `[WARN]` de "ningún modelo cargado" es normal (se carga al usar).
Si la config del servicio falla: `sudo ~/.dotfiles/scripts/setup-ollama-arc.sh` (re-aplica el drop-in).

## Stack y decisiones ya tomadas

| Pieza | Estado | Por qué |
|---|---|---|
| GPU | Intel Arc B570 (BMG G21), 10 GB, driver `xe`, Vulkan 1.4 | Es el motor; la iGPU Radeon Vega (512 MB, `gfx90c`) se descarta a propósito |
| Ollama | `ollama` + `ollama-vulkan` (cachyos-extra-v3) | `ollama-vulkan` aporta `libggml-vulkan.so`; sin él no se usa la Arc |
| Servicio | `ollama.service` del sistema (usuario `ollama`) + drop-in | El unit tiene `ProtectHome=yes`, por eso los modelos van a `/var/lib/ollama` |
| Modelos | `qwen3.5:9b` (daily driver), `qwen3.5:4b` (rápido) y `gemma4:12b` (máxima calidad, con MTP) | Los tres con visión + tools |
| No instalado | `llama.cpp`/`ggml-vulkan`, `whisper-cpp` | Decisión explícita: solo Ollama por ahora |

## Configuración esperada del servicio

Drop-in `/etc/systemd/system/ollama.service.d/override.conf`, generado por `scripts/setup-ollama-arc.sh` (ese script es la fuente de verdad: editar ahí, no el drop-in):

```
OLLAMA_FLASH_ATTENTION=1     OLLAMA_KV_CACHE_TYPE=q8_0
OLLAMA_CONTEXT_LENGTH=8192   OLLAMA_MAX_LOADED_MODELS=1
OLLAMA_KEEP_ALIVE=30m        OLLAMA_VULKAN=true (lo aporta el paquete)
```

## Rendimiento de referencia (medido el 18/10/2026)

| Modelo | VRAM | Reparto | tok/s |
|---|---|---|---|
| `qwen3.5:4b` | 3,2 GB | 100 % GPU | ~70 (prefill 138) |
| `qwen3.5:9b` | 5,6 GB | 100 % GPU | ~45 (prefill 108) |
| `gemma4:12b` | 7,3 GB | 48/49 capas en GPU | ~32 (prefill 192) |

- Hasta 9B Q4 entra entero en la Arc. El 12B deja 1 capa + KV en CPU, pero **igual anda más rápido que los 12B viejos** gracias al MTP.
- `gemma4:12b` trae decodificación especulativa nativa (`gemma4-assistant`, `draft-mtp`): `ollama ps` muestra el tamaño del draft (~905 MB), **no** del modelo completo. No confundirlo con una carga rota: el offload real está en el log (`load_tensors: offloaded 48/49 layers to GPU`).
- Comparación histórica: `gemma3:12b` (Q4_K_M) daba 17 tok/s con 12 % en CPU; `qwen3:8b` ~50. Los sucesores mejoran ambos.
- Si un modelo rinde la mitad de esto: sospechar otro proceso comiendo VRAM (juego, compositor), caída a CPU, o servicio sin el drop-in aplicado.
- Bajar el contexto a 4096 no mejora el reparto (18,3 vs 17,1 tok/s): no vale la pena.

## Gotchas

- Cualquier cambio en `/etc/systemd` o paquetes necesita sudo: pedirlo al usuario, no intentar rodearlo.
- El servicio corre como usuario `ollama`, no `jonathan`; `ollama pull` funciona igual (va por HTTP al daemon).
- Un solo modelo cargado a la vez (`MAX_LOADED_MODELS=1`): cambiar de modelo recarga (10-35 s).
- Los nodos `/dev/dri/renderD*` están en 0666: no hace falta el grupo `render`.
- Alias de shell en `config/.zsh_aliases`: `ai` (qwen3.5:9b), `ai-fast` (qwen3.5:4b), `ai-big` (gemma4:12b), `ai-models`, `ai-gpu`, `ai-svc`.
- En OpenCode V2 el provider `ollama` se **autodescubre** en `127.0.0.1:11434`; en `opencode.json` solo van los overrides (`capabilities` + `limit` 8192/4096) porque el modelo descubierto hereda el ctx máximo del modelo (131072) y no el cap del servicio. Después de editarlo hace falta `opencode service restart`; para verificar sin cortar la sesión: `opencode api --standalone get /api/model`.
- `make lint` corre shellcheck sobre `scripts/*.sh`, `install.sh`, `link.sh`, `check.sh`, `config/shell/path.sh` y `config/colors/palette.sh`: hoy pasa limpio, mantenerlo así al tocar shell.

## Recetas

**Agregar un modelo**: `ollama pull <modelo>` → `make ia` (verifica que Ollama y OpenCode lo vean) → declarar el **override** en `~/.config/opencode/opencode.json` (`providers.ollama.models` con `limit` 8192/4096; el `capabilities` lo infiere Ollama) → alias si hace falta → `opencode service restart` → commit.

**Diagnóstico de lentitud**: `ollama ps` (reparto), `journalctl -u ollama -b --no-pager | grep "inference compute"` (GPU y VRAM), `scripts/ollama-check.sh --bench <modelo>` (tok/s).

**Logs**: `journalctl -u ollama -b --no-pager | grep -i -E "vulkan|gpu|error"`.

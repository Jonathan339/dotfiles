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

~/.dotfiles/scripts/ollama-check.sh --bench gemma3:12b   # medir un modelo puntual
```

Esperado: `0 error(es)`. Un `[WARN]` de "ningún modelo cargado" es normal (se carga al usar).
Si la config del servicio falla: `sudo ~/.dotfiles/scripts/setup-ollama-arc.sh` (re-aplica el drop-in).

## Stack y decisiones ya tomadas

| Pieza | Estado | Por qué |
|---|---|---|
| GPU | Intel Arc B570 (BMG G21), 10 GB, driver `xe`, Vulkan 1.4 | Es el motor; la iGPU Radeon Vega (512 MB, `gfx90c`) se descarta a propósito |
| Ollama | `ollama` + `ollama-vulkan` (cachyos-extra-v3) | `ollama-vulkan` aporta `libggml-vulkan.so`; sin él no se usa la Arc |
| Servicio | `ollama.service` del sistema (usuario `ollama`) + drop-in | El unit tiene `ProtectHome=yes`, por eso los modelos van a `/var/lib/ollama` |
| Modelos | `qwen3:8b` (rápido) y `gemma3:12b` (mejor calidad + visión) | Ver tabla de rendimiento |
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
| `qwen3:8b` | 5,7 GB | 100 % GPU | ~50 |
| `gemma3:12b` | 7,9 GB | 88 % GPU / 12 % CPU | ~17 |

- 7-8B Q4 entra entero; 12-14B Q4 siempre queda ~10 % en CPU (10 GB de VRAM no dan para más).
- Si un modelo rinde la mitad de esto: sospechar otro proceso comiendo VRAM (juego, compositor), caída a CPU, o servicio sin el drop-in aplicado.
- `gemma3:12b-it-qat` (Q4_0) es **peor** en esta placa: 8,7 GB y 12,3 tok/s. No reemplaza al Q4_K_M.
- Bajar el contexto a 4096 no mejora el reparto (18,3 vs 17,1 tok/s): no vale la pena.

## Gotchas

- Cualquier cambio en `/etc/systemd` o paquetes necesita sudo: pedirlo al usuario, no intentar rodearlo.
- El servicio corre como usuario `ollama`, no `jonathan`; `ollama pull` funciona igual (va por HTTP al daemon).
- Un solo modelo cargado a la vez (`MAX_LOADED_MODELS=1`): cambiar de modelo recarga (10-35 s).
- Los nodos `/dev/dri/renderD*` están en 0666: no hace falta el grupo `render`.
- Alias de shell en `config/.zsh_aliases`: `ai` (gemma3:12b), `ai-fast` (qwen3:8b), `ai-models`, `ai-gpu`, `ai-svc`.
- En OpenCode el provider usa formato V2 (`providers.ollama` con `settings.baseURL`, `capabilities.tools` y `limit`); después de editarlo hace falta `opencode service restart` para recargar la config (y limpiar modelos fantasma).
- `make lint` corre shellcheck sobre `scripts/*.sh`, `install.sh`, `link.sh`, `check.sh`, `config/shell/path.sh` y `config/colors/palette.sh`: hoy pasa limpio, mantenerlo así al tocar shell.

## Recetas

**Agregar un modelo**: `ollama pull <modelo>` → declararlo en `~/.config/opencode/opencode.json` (`providers.ollama.models` con `capabilities` y `limit` acordes) → alias si hace falta → commit.

**Diagnóstico de lentitud**: `ollama ps` (reparto), `journalctl -u ollama -b --no-pager | grep "inference compute"` (GPU y VRAM), `scripts/ollama-check.sh --bench <modelo>` (tok/s).

**Logs**: `journalctl -u ollama -b --no-pager | grep -i -E "vulkan|gpu|error"`.

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

~/.dotfiles/scripts/ollama-check.sh --bench s1gnature/gemma4-uncensored-mtp:e2b-q4_k_m   # medir un modelo puntual
```

Esperado: `0 error(es)`. Un `[WARN]` de "ningún modelo cargado" es normal (se carga al usar).
Si la config del servicio falla: `sudo ~/.dotfiles/scripts/setup-ollama-arc.sh` (re-aplica el drop-in).

## Stack y decisiones ya tomadas

| Pieza | Estado | Por qué |
|---|---|---|
| GPU | Intel Arc B570 (BMG G21), 10 GB, driver `xe`, Vulkan 1.4 | Es el motor; la iGPU Radeon Vega (512 MB, `gfx90c`) se descarta a propósito |
| Ollama | `ollama` + `ollama-vulkan` (cachyos-extra-v3) | `ollama-vulkan` aporta `libggml-vulkan.so`; sin él no se usa la Arc |
| Servicio | `ollama.service` del sistema (usuario `ollama`) + drop-in | El unit tiene `ProtectHome=yes`, por eso los modelos van a `/var/lib/ollama` |
| Modelos | `qwen3.5:0.8b` (rápido/liviano), `s1gnature/gemma4-uncensored-mtp:e2b-q4_k_m` (daily driver, sin censura) y `…:e2b-q8_0` (misma familia, más precisión) | Los tres con tools reales verificados (`renderer_parser`) y 100 % en GPU. Se borraron los modelos sin visión/calidad que no entraban en el presupuesto de VRAM (ver "Probados y descartados") |
| llama.cpp | `llama-cpp` + `ggml-vulkan` (paquetes) y build local 0.7.0-dev en `~/.local/bin/llama` | El paquete trae 0.6.0; el build local soporta MTP (`--spec-type draft-mtp`) y es el que corre como servicio |
| No instalado | `whisper-cpp` | Sin uso por ahora |

## Configuración esperada del servicio

Drop-in `/etc/systemd/system/ollama.service.d/override.conf`, generado por `scripts/setup-ollama-arc.sh` (ese script es la fuente de verdad: editar ahí, no el drop-in):

```
OLLAMA_FLASH_ATTENTION=1     OLLAMA_KV_CACHE_TYPE=q8_0
OLLAMA_CONTEXT_LENGTH=32768  OLLAMA_MAX_LOADED_MODELS=1
OLLAMA_KEEP_ALIVE=30m        OLLAMA_VULKAN=true (lo aporta el paquete)
```

## llama.cpp (servidor propio, puerto 8080)

- Unit de **usuario** `llama-server.service`, en la capa host: archivo real `config/systemd/user/llama-server.service`, symlink en `stow/host/cachyos/systemd/.config/systemd/user/`. Usa el mismo nombre que el unit del paquete (`/usr/lib/systemd/user/llama-server.service`): el de `~/.config` gana.
- Flags: `serve -m ~/models/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf -a qwen3.5-9b -c 24576 -ngl 99 -fa on -ctk q8_0 -ctv q8_0 -np 1 -dev Vulkan0`.
- `-dev Vulkan0` fija la Arc; `Vulkan1` es la iGPU Radeon (se descarta). Si cambia el orden de enumeración, `llama-server --list-devices` lo muestra.
- `--jinja` viene activado por defecto (0.7.0): tools y `reasoning_content` funcionan sin flag extra.
- Gestión: `systemctl --user {status,restart} llama-server` y `journalctl --user -u llama-server -f`. Carga en frío ~60 s.
- Un modelo por proceso: otro modelo implica cambiar `--model`/`--alias` y reiniciar, o un segundo puerto con su propio provider.
- OpenCode lo consume por el provider `llamacpp` (ver skill `opencode-local`).

## Rendimiento de referencia (medido el 25/10/2026)

| Modelo | Disco | tok/s (decode) | Prefill (3,4k) | Reparto |
|---|---|---|---|---|
| `qwen3.5:0.8b` (752M, Q8_0) | 1,3 GB | 124–137 | 3.885 | 100 % GPU |
| `…e2b-q4_k_m` (4,65B, Q4_K_M) | 3,6 GB | 104–112 | 654 | 100 % GPU |
| `…e2b-q8_0` (4,65B, Q8_0) | 5,1 GB | 80–88 | 652 | 100 % GPU |

- **Techo de VRAM**: 9,9 GiB totales, ~8,4–8,5 GiB disponibles (el compositor come ~1,4 GiB). Un archivo de hasta **~7 GB entra 100 % en GPU**; 7–8 GB deja 1–3 capas en CPU (~25–35 tok/s, usable); >9 GB ya no es fluido.
- Las bandas de ±10 % son reales entre corridas (clocks/temperatura): no perseguir diferencias menores a eso.
- **Prefill importa con contexto largo**: la familia Qwen lee prompts ~2,4× más rápido que Gemma (1.393 vs ~570 tok/s con 3,4k tokens en el 4B/7B). En un agente con 32k de contexto eso es la diferencia entre esperar 6 s o 14 s antes del primer token.
- Los modelos con MTP (`gemma4-*`, `qwen3.5:0.8b`) traen decodificación especulativa (`draft-mtp`): `ollama ps` muestra el tamaño del draft (~375–484 MB), **no** del modelo completo. El offload real está en el log (`load_tensors: offloaded 33/33 layers to GPU`).
- Si un modelo rinde la mitad de esto: sospechar otro proceso comiendo VRAM (juego, compositor), caída a CPU, o servicio sin el drop-in aplicado.
- Bajar el contexto a 4096 no mejora el reparto (18,3 vs 17,1 tok/s): no vale la pena.
- **llama.cpp 9B (30/10/2026)**: `Qwen3.5-9B-Uncensored` Q4_K_M con `-c 24576` y KV `q8_0` → **46 tok/s** de decode y ~101 tok/s de prefill con prompt corto (no se midió prefill a 3,4k). Entra completo en GPU.

## Gotchas

- Cualquier cambio en `/etc/systemd` o paquetes necesita sudo: pedirlo al usuario, no intentar rodearlo.
- El servicio corre como usuario `ollama`, no `jonathan`; `ollama pull` funciona igual (va por HTTP al daemon).
- Un solo modelo cargado a la vez (`MAX_LOADED_MODELS=1`): cambiar de modelo recarga (10-35 s).
- **Un `tools` en `ollama show` no garantiza tool-calling**: verificarlo con `journalctl -u ollama -b --no-pager | grep "template selection"`; si el modelo sale `selected=gguf_chat_template renderer=""` (y no `selected=renderer_parser`), las herramientas no se inyectan ni se parsean. Señal rápida contra `/v1/chat/completions`: al agregar la tool el `prompt_tokens` **no sube** (~21-34 en vez de ~295) y el modelo **confabula** la respuesta en vez de llamarla. Los tres modelos actuales sí usan `renderer_parser`; los descartados por esto están en "Probados y descartados".
- Los nodos `/dev/dri/renderD*` están en 0666: no hace falta el grupo `render`.
- **llama.cpp y Ollama compiten por la misma VRAM** (10 GB): si Ollama tiene un modelo cargado y arranca el 9B de llama.cpp, uno de los dos se cae a CPU. Antes de usar el 9B: `ollama stop <modelo>`. Chequeo rápido: si el decode cae a ~5-10 tok/s, es reparto en CPU.
- Alias de shell en `config/.zsh_aliases`: solo informativos (`ai-models`, `ai-gpu`, `ai-svc`). No hay atajos `ai`/`ai-fast`/`ai-big` desde 25/10/2026: apuntaban a modelos borrados y se eliminaron. Lanzar un modelo es `ollama run <modelo>`.
- **Autocompletado de zsh** en `config/shell/completions/_ollama`: completa subcomandos y los modelos instalados (`run`, `show`, `rm`, `stop`, `cp`, `push`). Cachea la lista 1 minuto en `~/.cache/zsh/ollama-models`; si sacás un modelo nuevo y no aparece, borrá ese archivo. Se activa al final de `config/.zshrc` (`fpath` + `compdef`), después de `compinit`.
- En OpenCode V2 el provider `ollama` se **autodescubre** en `127.0.0.1:11434`; en `opencode.json` solo van los overrides (`capabilities` + `limit` 32768/4096) porque el modelo descubierto hereda el ctx máximo del modelo (131072/262144) y no el cap del servicio. Después de editarlo hace falta `opencode service restart`; para verificar sin cortar la sesión: `opencode api --standalone get /api/model`.
- `make lint` corre shellcheck sobre `scripts/*.sh`, `install.sh`, `link.sh`, `check.sh`, `config/shell/path.sh` y `config/colors/palette.sh`: hoy pasa limpio, mantenerlo así al tocar shell.

## Probados y descartados

Se probaron modelos y se borraron; no volver a bajarlos sin motivo:

- `bonsai-2:9b` (9B, **Q2_0**, 3,2 GB): 26 tok/s con todo en GPU, la mitad que el resto. La cuantización a 2 bits tiene kernels pobres en Vulkan y encima degrada la calidad. Borrado el 25/10/2026.
- `gemma4:e4b`/`gemma4:latest` (7,5B Q4_K_M), `Gemma-4-E4B-Uncensored Q3_K_M` y `Qwen3.5-4B-Uncensored Q8_0`: borrados el 25/10/2026 al recortar el set a los tres modelos rápidos. Ojo con datos medidos: `gemma4:e4b` daba ~62 tok/s y prefill 565; el Qwen3.5-4B-Uncensored Q8 era el más lento generando (57) pero el mejor leyendo contexto (prefill 1.393).
- `Qwen3.5-4B-Uncensored-HauhauCS-Aggressive:Q8_0` (HF): declaraba `tools` en la metadata pero caía en `selected=gguf_chat_template renderer=""` → **nunca tuvo tool-calling real**, aunque `opencode.json` lo declaraba `tools: true`. Ejemplo de manual del gotcha de abajo.
- `UncensoredAi/diddy:latest` (llama 1.5B, 955 MB): declara `tools` pero cae en `selected=go_template renderer=""` → **no inyecta ni parsea herramientas**.
- `wizard-vicuna-uncensored:latest` (7B Q4_0, Llama 2 de 2023): renderer viejo, sin tools ni visión, contexto nativo 4096; peor que el Gemma-4-Uncensored en todo. Se bajó y se borró el mismo día.
- `deepseek-r1:latest` (8.2B Q4_K_M): razona bien pero **sin tools** (Ollama no le inyecta herramientas) y sin visión.
- `gemma3:12b` (Q4_K_M): 17 tok/s con 12 % en CPU; superado por los modelos actuales.

Lección: para modelos cuyo contexto nativo es menor que el cap del servicio (ej. Llama 2 = 4096 vs `OLLAMA_CONTEXT_LENGTH=32768`), declarar `limit.context` en el tamaño nativo en `opencode.json`.

## Recetas

**Agregar un modelo**: `ollama pull <modelo>` → `make ia` (verifica que Ollama y OpenCode lo vean) → **verificar el soporte real de tools** (gotchas: la metadata puede mentir) → declarar el **override** en `~/.config/opencode/opencode.json` (`providers.ollama.models` con `limit` 32768/4096 y, si no hace tool-calling, `capabilities.tools: false`) → `rm -f ~/.cache/zsh/ollama-models` para que el autocompletado lo vea → `opencode service restart` → commit.

**Diagnóstico de lentitud**: `ollama ps` (reparto), `journalctl -u ollama -b --no-pager | grep "inference compute"` (GPU y VRAM), `scripts/ollama-check.sh --bench <modelo>` (tok/s).

**Logs**: `journalctl -u ollama -b --no-pager | grep -i -E "vulkan|gpu|error"`.

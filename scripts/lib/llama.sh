#!/usr/bin/env bash
# lib/llama.sh — helpers compartidos por scripts/llama-*.sh
#
# No se ejecuta solo: se sourcea. Los serve.sh de ~/models declaran sus flags
# como `var="${var:-default}"`; acá se leen esos defaults para no duplicar
# alias, puerto y contexto en la config de OpenCode ni en el journal.

# serve_var <serve.sh> <var> → imprime el default de `var="${var:-...}"`.
# Devuelve 1 si el script no declara la variable con ese patrón.
serve_var() {
  local file=$1 name=$2 line re
  line=$(grep -m1 -E "^${name}=\"\\\$\\{${name}:-" "$file" 2>/dev/null) || return 1
  re="^${name}=\"\\\$\\{${name}:-([^}]*)\\}\""
  [[ $line =~ $re ]] || return 1
  printf '%s\n' "${BASH_REMATCH[1]}"
}

# serve_model_dir <alias> → ruta del serve.sh cuyo alias coincide.
# Devuelve 1 si ningún modelo de ~/models usa ese alias.
serve_model_dir() {
  local alias=$1 dir candidato
  for dir in "${MODELS_DIR:?MODELS_DIR no definido}"/*/; do
    [[ -f "${dir}serve.sh" ]] || continue
    candidato=$(serve_var "${dir}serve.sh" alias) || continue
    if [[ $candidato == "$alias" ]]; then
      printf '%s\n' "${dir}serve.sh"
      return 0
    fi
  done
  return 1
}

# api_models <base-url> → JSON de /v1/models. Falla si el server no responde
# (503 mientras carga el modelo, conexión rechazada, etc.).
api_models() {
  curl -fsS --max-time 5 "${1}/models" 2>/dev/null
}

# llama_unit_pid <unit> → MainPID del unit (0 si no corre).
llama_unit_pid() {
  systemctl --user show -p MainPID --value "$1" 2>/dev/null || echo 0
}

# llama_pid_cmdline <pid> → cmdline con espacios (vacío si no existe).
llama_pid_cmdline() {
  tr '\0' ' ' < "/proc/$1/cmdline" 2>/dev/null || true
}

# llama_pid_vram_kib <pid> → KiB residentes en VRAM del proceso.
# Suma drm-resident-vram0 de todos sus fdinfo (driver xe/i915).
llama_pid_vram_kib() {
  local pid=$1 total=0 f val
  [[ $pid =~ ^[0-9]+$ && -d /proc/$pid/fdinfo ]] || { echo 0; return 0; }
  for f in /proc/"$pid"/fdinfo/*; do
    [[ -r $f ]] || continue
    val=$(awk '/^drm-resident-vram0:/{print $2; exit}' "$f" 2>/dev/null || true)
    [[ -n $val ]] && total=$((total + val))
  done
  printf '%s\n' "$total"
}

# llama_vram_of_llama_processes → KiB de VRAM sumados de todos los procesos
# llama/llama-server vivos (no solo el del unit).
llama_vram_of_llama_processes() {
  local d pid total=0
  for d in /proc/[0-9]*; do
    [[ -r $d/cmdline ]] || continue
    pid=${d#/proc/}
    if llama_pid_cmdline "$pid" | grep -qE '(^|[[:space:]/])(llama|llama-server)([[:space:]]|$)'; then
      total=$((total + $(llama_pid_vram_kib "$pid")))
    fi
  done
  printf '%s\n' "$total"
}

# llama_wait_unit_stopped <unit> <timeout_seg> → espera a que el MainPID muera.
llama_wait_unit_stopped() {
  local unit=$1 timeout=${2:-30} pid waited=0
  pid=$(llama_unit_pid "$unit")
  [[ $pid =~ ^[0-9]+$ && $pid -gt 0 ]] || return 0
  while kill -0 "$pid" 2>/dev/null; do
    if (( waited >= timeout * 10 )); then
      return 1
    fi
    sleep 0.1
    waited=$((waited + 1))
  done
  return 0
}

# llama_wait_vram_released <max_kib> <timeout_seg> → 0 si la VRAM de procesos
# llama baja del umbral; si no, imprime el valor restante y devuelve 1.
llama_wait_vram_released() {
  local max_kib=${1:-262144} timeout=${2:-20} waited=0 used
  while true; do
    used=$(llama_vram_of_llama_processes)
    (( used <= max_kib )) && return 0
    if (( waited >= timeout * 5 )); then
      printf '%s\n' "$used"
      return 1
    fi
    sleep 0.2
    waited=$((waited + 1))
  done
}

# llama_arc_mem → "total_mib free_mib" de la Intel Arc según --list-devices.
# Vacío si la Arc no aparece.
llama_arc_mem() {
  local bin=${LLAMA_BIN:-$HOME/.local/bin/llama}
  "$bin" serve --list-devices 2>/dev/null \
    | sed -nE 's/^[[:space:]]*Vulkan[0-9]+:.*(B570|BMG[[:space:]]*G21).*\(([0-9]+) MiB, ([0-9]+) MiB free\).*/\2 \3/p' \
    | head -1
}

# llama_stop_ollama_models → descarga los modelos de Ollama para liberar VRAM.
# No falla si Ollama no está instalado o no responde.
llama_stop_ollama_models() {
  command -v ollama >/dev/null 2>&1 || return 0
  local m modelos waited=0
  modelos=$(ollama ps 2>/dev/null | awk 'NR > 1 && NF {print $1}') || return 0
  [[ -n $modelos ]] || return 0
  while IFS= read -r m; do
    [[ -n $m ]] || continue
    ollama stop "$m" >/dev/null 2>&1 || true
  done <<< "$modelos"
  while [[ -n $(ollama ps 2>/dev/null | awk 'NR > 1 && NF {print $1; exit}') ]]; do
    (( waited >= 150 )) && break
    sleep 0.2
    waited=$((waited + 1))
  done
  return 0
}

# llama_kill_strays <puerto> <pid_excluido> → termina procesos llama que
# escuchan en el puerto y no son el MainPID del unit.
llama_kill_strays() {
  local port=$1 excluir=${2:-0} pids pid cmd waited=0
  command -v ss >/dev/null 2>&1 || return 0
  pids=$(ss -H -ltnp "sport = :$port" 2>/dev/null | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u || true)
  [[ -n $pids ]] || return 0
  for pid in $pids; do
    [[ $pid == "$excluir" ]] && continue
    cmd=$(llama_pid_cmdline "$pid")
    [[ $cmd == *llama* ]] || continue
    kill -TERM "$pid" 2>/dev/null || true
  done
  for pid in $pids; do
    [[ $pid == "$excluir" ]] && continue
    while kill -0 "$pid" 2>/dev/null; do
      if (( waited >= 100 )); then
        kill -KILL "$pid" 2>/dev/null || true
        break
      fi
      sleep 0.1
      waited=$((waited + 1))
    done
  done
  return 0
}

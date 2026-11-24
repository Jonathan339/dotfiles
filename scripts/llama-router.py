#!/usr/bin/env python3
"""llama-router.py — cambia de modelo bajo demanda para llama.cpp.

Escucha en 127.0.0.1:8082 (lo que consume OpenCode) y reenvía al backend
llama-server en 127.0.0.1:8083. Si la petición pide un alias distinto del
cargado, para el backend, espera a que la VRAM se libere, descarga modelos de
Ollama que ocupen la GPU, arranca el modelo pedido y reenvía la petición.

El mapa alias → serve.sh se lee de ~/models/*/serve.sh, la misma fuente que usa
llama-model.sh. Un solo modelo vive en la GPU a la vez: las peticiones
concurrentes esperan el mismo lock.
"""

from __future__ import annotations

import http.client
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MODELS_DIR = os.path.expanduser(os.environ.get("MODELS_DIR", "~/models"))
LISTEN_HOST = os.environ.get("LISTEN_HOST", "127.0.0.1")
LISTEN_PORT = int(os.environ.get("LISTEN_PORT", "8082"))
BACKEND_HOST = os.environ.get("BACKEND_HOST", "127.0.0.1")
BACKEND_PORT = int(os.environ.get("BACKEND_PORT", "8083"))
UNIT = os.environ.get("UNIT", "llama-server")
LINK = os.environ.get("LINK", "~/.config/llama-current")
LOAD_TIMEOUT = int(os.environ.get("LOAD_TIMEOUT", "300"))
PROXY_TIMEOUT = int(os.environ.get("PROXY_TIMEOUT", "600"))
STOP_OLLAMA = os.environ.get("STOP_OLLAMA", "1") not in ("0", "false", "no")
VRAM_MAX_KIB = int(os.environ.get("VRAM_MAX_KIB", str(256 * 1024)))

HOP_BY_HOP = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailer",
    "transfer-encoding",
    "upgrade",
    "host",
    "content-length",
}

# RLock: una petición que cambia el modelo mantiene el lock también mientras
# reenvía, así otra petición no puede parar el backend a mitad de respuesta.
# Con un solo slot en llama.cpp esto no reduce el rendimiento real.
LOCK = threading.RLock()
MODELS: dict[str, str] = {}


def log(msg: str) -> None:
    print(f"{time.strftime('%H:%M:%S')} llama-router: {msg}", file=sys.stderr, flush=True)


def run(cmd: list[str], timeout: int = 60) -> subprocess.CompletedProcess[str] | None:
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.SubprocessError) as exc:
        log(f"error ejecutando {' '.join(cmd)}: {exc}")
        return None


def unit_pid() -> int:
    result = run(["systemctl", "--user", "show", "-p", "MainPID", "--value", UNIT], timeout=10)
    if not result or result.returncode != 0:
        return 0
    try:
        return int(result.stdout.strip() or "0")
    except ValueError:
        return 0


def pid_vram_kib(pid: int) -> int:
    total = 0
    base = f"/proc/{pid}/fdinfo"
    try:
        entries = os.listdir(base)
    except OSError:
        return 0
    for name in entries:
        try:
            with open(os.path.join(base, name), encoding="utf-8", errors="ignore") as handle:
                for line in handle:
                    if line.startswith("drm-resident-vram0:"):
                        total += int(line.split()[1])
                        break
        except (OSError, ValueError, IndexError):
            continue
    return total


def llama_vram_kib() -> int:
    total = 0
    try:
        entries = os.listdir("/proc")
    except OSError:
        return 0
    for entry in entries:
        if not entry.isdigit():
            continue
        try:
            with open(f"/proc/{entry}/cmdline", "rb") as handle:
                cmdline = handle.read().replace(b"\0", b" ").decode("utf-8", "ignore")
        except OSError:
            continue
        if re.search(r"(^|[\s/])(llama|llama-server)(\s|$)", cmdline):
            total += pid_vram_kib(int(entry))
    return total


def wait_vram_released(timeout: int = 20) -> bool:
    deadline = time.time() + timeout
    while True:
        used = llama_vram_kib()
        if used <= VRAM_MAX_KIB:
            return True
        if time.time() >= deadline:
            log(f"VRAM de procesos llama aún ocupada: {used // 1024} MiB")
            return False
        time.sleep(0.3)


def stop_backend() -> None:
    pid = unit_pid()
    if pid:
        log(f"parando {UNIT} (pid {pid})")
        run(["systemctl", "--user", "stop", UNIT], timeout=60)
    deadline = time.time() + 30
    while unit_pid():
        if time.time() >= deadline:
            log("el backend no terminó; enviando SIGKILL al cgroup")
            run(["systemctl", "--user", "kill", "-s", "SIGKILL", UNIT], timeout=30)
            time.sleep(1)
            break
        time.sleep(0.2)


def stop_ollama() -> None:
    if not STOP_OLLAMA or not shutil.which("ollama"):
        return
    result = run(["ollama", "ps"], timeout=15)
    if not result or result.returncode != 0:
        return
    loaded = [line.split()[0] for line in result.stdout.splitlines()[1:] if line.strip()]
    for model in loaded:
        log(f"descargando modelo de Ollama: {model}")
        run(["ollama", "stop", model], timeout=30)
    deadline = time.time() + 30
    while time.time() < deadline:
        result = run(["ollama", "ps"], timeout=10)
        if not result or result.returncode != 0:
            return
        if not [line for line in result.stdout.splitlines()[1:] if line.strip()]:
            return
        time.sleep(0.3)


def backend_alias(timeout: int = 2) -> str | None:
    conn = http.client.HTTPConnection(BACKEND_HOST, BACKEND_PORT, timeout=timeout)
    try:
        conn.request("GET", "/v1/models")
        response = conn.getresponse()
        if response.status != 200:
            return None
        payload = json.loads(response.read() or b"{}")
        items = payload.get("data") or []
        return items[0].get("id") if items else None
    except (OSError, ValueError, http.client.HTTPException):
        return None
    finally:
        conn.close()


def wait_backend_alias(alias: str, timeout: int) -> bool:
    deadline = time.time() + timeout
    while time.time() < deadline:
        if backend_alias() == alias:
            return True
        result = run(["systemctl", "--user", "is-active", "--quiet", UNIT], timeout=10)
        if result and result.returncode != 0:
            log("el backend dejó de estar activo")
            return False
        time.sleep(2)
    return False


def ensure_model(alias: str) -> bool:
    with LOCK:
        current = backend_alias()
        if current == alias:
            return True
        log(f"modelo pedido: {alias} (cargado: {current or 'ninguno'})")
        started = time.time()
        stop_backend()
        if not wait_vram_released():
            return False
        stop_ollama()
        target = MODELS[alias]
        link = os.path.expanduser(LINK)
        try:
            if os.path.lexists(link):
                os.unlink(link)
            os.symlink(target, link)
        except OSError as exc:
            log(f"no pude actualizar {link}: {exc}")
            return False
        log(f"selector -> {target}")
        result = run(["systemctl", "--user", "start", UNIT], timeout=60)
        if not result or result.returncode != 0:
            log("no se pudo arrancar el backend")
            return False
        if wait_backend_alias(alias, LOAD_TIMEOUT):
            log(f"{alias} listo en {time.time() - started:.0f}s")
            return True
        log(f"timeout esperando {alias}")
        return False


def load_models() -> dict[str, str]:
    models: dict[str, str] = {}
    try:
        entries = sorted(os.listdir(MODELS_DIR))
    except OSError as exc:
        log(f"no pude leer {MODELS_DIR}: {exc}")
        return models
    for name in entries:
        serve = os.path.join(MODELS_DIR, name, "serve.sh")
        if not os.path.isfile(serve):
            continue
        try:
            with open(serve, encoding="utf-8") as handle:
                text = handle.read()
        except OSError:
            continue
        match = re.search(r'^alias="\$\{alias:-([^}]*)\}"', text, re.MULTILINE)
        if match:
            models[match.group(1)] = serve
    return models


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "llama-router"

    def log_message(self, fmt: str, *args: object) -> None:
        log(f"{self.client_address[0]} {fmt % args}")

    # -- helpers -------------------------------------------------------------
    def send_json(self, status: int, payload: dict[str, object]) -> None:
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_error_json(self, status: int, message: str) -> None:
        self.send_json(
            status,
            {"error": {"message": message, "type": "router_error", "code": status}},
        )

    def read_body(self) -> bytes:
        transfer = (self.headers.get("Transfer-Encoding") or "").lower()
        if "chunked" in transfer:
            chunks: list[bytes] = []
            while True:
                line = self.rfile.readline().strip()
                if not line:
                    break
                size = int(line.split(b";")[0], 16)
                if size == 0:
                    self.rfile.readline()
                    break
                chunks.append(self.rfile.read(size))
                self.rfile.read(2)
            return b"".join(chunks)
        try:
            length = int(self.headers.get("Content-Length") or 0)
        except ValueError:
            length = 0
        return self.rfile.read(length) if length else b""

    def proxy(self, method: str, body: bytes | None = None) -> None:
        headers = {
            key: value
            for key, value in self.headers.items()
            if key.lower() not in HOP_BY_HOP
        }
        headers["Host"] = f"{BACKEND_HOST}:{BACKEND_PORT}"
        conn = http.client.HTTPConnection(
            BACKEND_HOST, BACKEND_PORT, timeout=PROXY_TIMEOUT
        )
        try:
            conn.request(method, self.path, body=body, headers=headers)
            response = conn.getresponse()
        except (OSError, http.client.HTTPException) as exc:
            conn.close()
            self.send_error_json(502, f"backend no disponible: {exc}")
            return
        try:
            self.send_response_only(response.status)
            for key, value in response.getheaders():
                if key.lower() in HOP_BY_HOP:
                    continue
                self.send_header(key, value)
            self.send_header("Connection", "close")
            self.end_headers()
            self.close_connection = True
            if method != "HEAD" and response.status not in (204, 304):
                while True:
                    chunk = response.read(65536)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            pass
        finally:
            conn.close()

    # -- rutas ---------------------------------------------------------------
    def do_GET(self) -> None:
        path = self.path.split("?", 1)[0]
        if path in ("/health", "/healthz"):
            alias = backend_alias()
            if alias:
                self.send_json(200, {"status": "ok", "model": alias})
            else:
                self.send_json(503, {"status": "loading-or-down"})
            return
        if path in ("/v1/models", "/models"):
            now = int(time.time())
            data = [
                {"id": alias, "object": "model", "created": now, "owned_by": "local"}
                for alias in sorted(MODELS)
            ]
            self.send_json(200, {"object": "list", "data": data})
            return
        self.proxy("GET")

    def do_HEAD(self) -> None:
        self.proxy("HEAD")

    def do_POST(self) -> None:
        with LOCK:
            body = self.read_body()
            model = None
            if body:
                try:
                    payload = json.loads(body)
                    if isinstance(payload, dict):
                        model = payload.get("model")
                except ValueError:
                    model = None
            if model:
                if model not in MODELS:
                    self.send_error_json(404, f"modelo desconocido: {model}")
                    return
                if not ensure_model(model):
                    self.send_error_json(503, f"no se pudo cargar el modelo {model}")
                    return
            self.proxy("POST", body)

    def do_PUT(self) -> None:
        self.proxy("PUT", self.read_body())

    def do_DELETE(self) -> None:
        self.proxy("DELETE")


def main() -> int:
    global MODELS
    MODELS = load_models()
    if not MODELS:
        log(f"no hay modelos con serve.sh en {MODELS_DIR}")
        return 1
    server = ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), Handler)
    server.daemon_threads = True
    log(f"escuchando en http://{LISTEN_HOST}:{LISTEN_PORT} -> {BACKEND_HOST}:{BACKEND_PORT}")
    log(f"modelos: {', '.join(sorted(MODELS))}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

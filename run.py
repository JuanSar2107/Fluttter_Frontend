#!/usr/bin/env python3
"""Small helper to manage local running and Docker Compose deployment."""

from __future__ import annotations

import argparse
import http.server
import os
import socketserver
import subprocess
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
DOCKER_COMMANDS = {
    "up": ["up", "--build", "-d"],
    "down": ["down"],
    "logs": ["logs", "-f", "web"],
    "status": ["ps"],
}


class SpaHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        build_dir = os.path.join(ROOT, "build", "web")
        super().__init__(*args, directory=build_dir, **kwargs)

    def do_GET(self):
        path = self.translate_path(self.path)
        if not os.path.exists(path) and "." not in self.path.split("/")[-1]:
            self.path = "/index.html"
        return super().do_GET()


def serve_local(port: int = 8044) -> int:
    build_dir = os.path.join(ROOT, "build", "web")
    if not os.path.exists(build_dir):
        print(f"Directorio {build_dir} no encontrado. Compilando...")
        res = subprocess.run(["flutter", "build", "web", "--release", "--base-href=/"], cwd=ROOT)
        if res.returncode != 0:
            return res.returncode

    print(f"\n[OK] Servidor local iniciado en: http://localhost:{port}")
    print("Presiona Ctrl+C para detener el servidor.\n")
    try:
        with socketserver.TCPServer(("127.0.0.1", port), SpaHandler) as httpd:
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServidor detenido.")
    return 0


def run_flutter_dev() -> int:
    print("Iniciando Flutter en modo desarrollo con Google Chrome...")
    return subprocess.run(["flutter", "run", "-d", "chrome"], cwd=ROOT).returncode


def main() -> int:
    parser = argparse.ArgumentParser(description="Gestionar la aplicación Flutter Web localmente o con Docker.")
    parser.add_argument(
        "action",
        nargs="?",
        default="serve",
        choices=["serve", "dev", "up", "down", "logs", "status"],
        help="Acción a ejecutar: 'serve' (servidor local puerto 8044), 'dev' (flutter run con hot reload), o comandos docker (up, down, logs, status)",
    )
    args = parser.parse_args()

    if args.action == "serve":
        return serve_local()

    if args.action == "dev":
        return run_flutter_dev()

    # Comandos Docker
    command = [
        "docker",
        "compose",
        "-f",
        os.path.join(ROOT, "docker-compose.yml"),
        "-f",
        os.path.join(ROOT, "docker-compose.local.yml"),
        *DOCKER_COMMANDS[args.action],
    ]
    try:
        return subprocess.run(command, cwd=ROOT, check=False).returncode
    except FileNotFoundError:
        print(
            "No se encontró Docker en el sistema. Puedes correr en local sin Docker usando:\n"
            "  python run.py serve   (sirve la versión web en http://localhost:8044)\n"
            "  python run.py dev     (inicia Flutter con Hot Reload en Chrome)\n",
            file=sys.stderr,
        )
        return 127


if __name__ == "__main__":
    raise SystemExit(main())

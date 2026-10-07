#!/usr/bin/env python3
"""Small helper to manage the local Docker Compose deployment."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys


ROOT = os.path.dirname(os.path.abspath(__file__))
COMMANDS = {
    "up": ["up", "--build", "-d"],
    "down": ["down"],
    "logs": ["logs", "-f", "web"],
    "status": ["ps"],
}


def main() -> int:
    parser = argparse.ArgumentParser(description="Manage the Flutter web app with Docker Compose.")
    parser.add_argument("action", choices=COMMANDS, help="Compose action to run")
    args = parser.parse_args()

    command = [
        "docker",
        "compose",
        "-f",
        os.path.join(ROOT, "docker-compose.yml"),
        "-f",
        os.path.join(ROOT, "docker-compose.local.yml"),
        *COMMANDS[args.action],
    ]
    try:
        return subprocess.run(command, cwd=ROOT, check=False).returncode
    except FileNotFoundError:
        print("No se encontró Docker. Instala Docker Engine con el plugin Docker Compose.", file=sys.stderr)
        return 127


if __name__ == "__main__":
    raise SystemExit(main())

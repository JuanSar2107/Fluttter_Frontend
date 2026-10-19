#!/usr/bin/env python3
"""Genera los iconos de la app (favicon, PWA y launcher de Android).

Reproduce el `_RotorPainter` de `lib/features/auth/presentation/widgets/app_logo.dart`:
si cambias el logo alli, ajusta tambien este script y vuelve a ejecutarlo.

    python3 tool/generate_icons.py

Requiere Pillow (`pip install pillow`).
"""

from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# AppColors
NAVY_DEEP = (0x06, 0x15, 0x24)
NAVY = (0x0B, 0x22, 0x39)
NAVY_LIGHT = (0x16, 0x38, 0x5A)
AMBER = (0xFF, 0x9F, 0x1C)
WHITE = (255, 255, 255)

# Se dibuja a 4x y se reduce, para tener bordes suavizados.
SUPERSAMPLE = 4


def _lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def _gradient(size: int) -> Image.Image:
    """`AppColors.brandGradient`: arriba-izquierda a abajo-derecha, 3 paradas."""
    n = 256
    small = Image.new("RGB", (n, n))
    px = small.load()
    for y in range(n):
        for x in range(n):
            t = (x + y) / (2 * (n - 1))
            px[x, y] = _lerp(NAVY_DEEP, NAVY, t * 2) if t < 0.5 else _lerp(NAVY, NAVY_LIGHT, (t - 0.5) * 2)
    return small.resize((size, size), Image.BILINEAR)


def _quad(p0, c, p1, steps=24):
    return [
        (
            (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t**2 * p1[0],
            (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t**2 * p1[1],
        )
        for t in (i / steps for i in range(steps + 1))
    ]


def _draw_rotor(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float) -> None:
    blade = _quad((0, -r * 0.14), (r * 0.62, -r * 0.34), (r * 0.84, -r * 0.10))
    blade += _quad((r * 0.84, -r * 0.10), (r * 0.60, r * 0.06), (0, r * 0.14))[1:]
    for i in range(4):
        a = i * 2 * math.pi / 4 + 0.4
        cos, sin = math.cos(a), math.sin(a)
        draw.polygon([(cx + x * cos - y * sin, cy + x * sin + y * cos) for x, y in blade], fill=AMBER)

    def circle(radius, fill):
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=fill)

    circle(r * 0.20, WHITE)
    circle(r * 0.09, _lerp(WHITE, AMBER, 0.85))


def render(size: int, *, background: str = "rounded", rotor_scale: float = 1.0) -> Image.Image:
    """background: 'rounded' (como en la app), 'square' (maskable) o 'none' (solo rotor)."""
    s = size * SUPERSAMPLE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    if background != "none":
        bg = _gradient(s).convert("RGBA")
        mask = Image.new("L", (s, s), 0)
        if background == "rounded":
            ImageDraw.Draw(mask).rounded_rectangle((0, 0, s - 1, s - 1), radius=s * 0.28, fill=255)
        else:
            mask.paste(255, (0, 0, s, s))
        img.paste(bg, (0, 0), mask)
    if rotor_scale > 0:
        _draw_rotor(ImageDraw.Draw(img), s / 2, s / 2, s / 2 * rotor_scale)
    return img.resize((size, size), Image.LANCZOS)


def save(img: Image.Image, *parts: str) -> None:
    path = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)
    print("  ", os.path.relpath(path, ROOT))


def main() -> None:
    print("Web:")
    save(render(64), "web", "favicon.png")
    for n in (192, 512):
        save(render(n), "web", "icons", f"Icon-{n}.png")
        # Maskable: el navegador recorta hasta el 80 % central.
        save(render(n, background="square", rotor_scale=0.8), "web", "icons", f"Icon-maskable-{n}.png")

    print("Android:")
    res = ("android", "app", "src", "main", "res")
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, k in densities.items():
        # Icono clasico (Android 7 y anteriores).
        save(render(round(48 * k)), *res, f"mipmap-{name}", "ic_launcher.png")
        # Icono adaptativo (Android 8+): capas de 108 dp; el launcher recorta
        # la forma y solo garantiza visibles los 66 dp centrales.
        layer = round(108 * k)
        save(render(layer, background="none", rotor_scale=0.62), *res, f"mipmap-{name}", "ic_launcher_foreground.png")
        save(render(layer, background="square", rotor_scale=0), *res, f"mipmap-{name}", "ic_launcher_background.png")


if __name__ == "__main__":
    main()

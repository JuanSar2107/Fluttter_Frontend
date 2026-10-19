#!/usr/bin/env bash
# Compila la app de escritorio para Linux y la empaqueta en
# web/downloads/aeroparts-linux-x64.tar.gz (la descarga que ofrece la web).
#
#     bash tool/package_linux.sh
#
# Requiere en la maquina que compila: clang, cmake, ninja, gtk3-devel y
# libsecret-devel (Fedora) / libgtk-3-dev y libsecret-1-dev (Debian/Ubuntu).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_ID="com.aeroparts.aviation_inventory"
STAGE="$ROOT/build/linux-package/aeroparts"
OUT="$ROOT/web/downloads/aeroparts-linux-x64.tar.gz"

cd "$ROOT"
flutter build linux --release

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -r build/linux/x64/release/bundle/. "$STAGE/"
cp web/icons/Icon-512.png "$STAGE/aeroparts.png"

cat > "$STAGE/install.sh" <<'INSTALL'
#!/usr/bin/env bash
# Instala AeroParts para el usuario actual (sin sudo) y lo agrega al menu.
set -euo pipefail
APP_ID="com.aeroparts.aviation_inventory"
SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.local/share/aeroparts"

rm -rf "$DEST"
mkdir -p "$DEST" "$HOME/.local/share/applications" "$HOME/.local/share/icons/hicolor/512x512/apps"
cp -r "$SRC/." "$DEST/"
cp "$SRC/aeroparts.png" "$HOME/.local/share/icons/hicolor/512x512/apps/$APP_ID.png"

cat > "$HOME/.local/share/applications/$APP_ID.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=AeroParts
Comment=Inventario de repuestos aeronauticos
Exec=$DEST/aeroparts
Icon=$APP_ID
Terminal=false
Categories=Office;
StartupWMClass=$APP_ID
DESKTOP

update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
echo "AeroParts instalado. Buscalo en el menu de aplicaciones."
INSTALL

cat > "$STAGE/uninstall.sh" <<'UNINSTALL'
#!/usr/bin/env bash
APP_ID="com.aeroparts.aviation_inventory"
rm -rf "$HOME/.local/share/aeroparts"
rm -f "$HOME/.local/share/applications/$APP_ID.desktop" \
      "$HOME/.local/share/icons/hicolor/512x512/apps/$APP_ID.png"
echo "AeroParts desinstalado."
UNINSTALL

chmod +x "$STAGE/install.sh" "$STAGE/uninstall.sh" "$STAGE/aeroparts"
mkdir -p "$(dirname "$OUT")"
tar -czf "$OUT" -C "$(dirname "$STAGE")" aeroparts
echo "Paquete listo: ${OUT#$ROOT/} ($(du -h "$OUT" | cut -f1))"

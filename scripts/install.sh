#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLASMOID_FILE="$ROOT_DIR/dist/org.local.plasmastats.plasmoid"
PKG_DIR="$ROOT_DIR/package"
APPLET_ID="org.local.plasmastats"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "Error: kpackagetool6 not found. Please install KDE Plasma 6 tools." >&2
    exit 1
fi

TARGET="$PKG_DIR"
if [[ -f "$PLASMOID_FILE" ]]; then
    TARGET="$PLASMOID_FILE"
fi

if kpackagetool6 -t Plasma/Applet -s "$APPLET_ID" >/dev/null 2>&1; then
    echo "Upgrading existing $APPLET_ID from $TARGET ..."
    kpackagetool6 -t Plasma/Applet -u "$TARGET"
else
    echo "Installing $APPLET_ID from $TARGET ..."
    kpackagetool6 -t Plasma/Applet -i "$TARGET"
fi

echo ""
echo "Done! Installed to: ~/.local/share/plasma/plasmoids/$APPLET_ID"
echo "Next steps:"
echo "  1. Right-click your KDE panel -> Enter Edit Mode -> Add Widgets..."
echo "  2. Search for 'Plasma Stats' and drag it onto the panel."
echo "  3. If upgrading an already-loaded widget, reload Plasma shell:"
echo "     systemctl --user restart plasma-plasmashell.service"

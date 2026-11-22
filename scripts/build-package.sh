#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="$ROOT_DIR/package"
DIST_DIR="$ROOT_DIR/dist"
VERSION="1.0.0"
APPLET_ID="org.local.plasmastats"

mkdir -p "$DIST_DIR"

PLASMOID_OUT="$DIST_DIR/${APPLET_ID}-${VERSION}.plasmoid"
PLASMOID_LATEST="$DIST_DIR/${APPLET_ID}.plasmoid"
TARBALL_OUT="$DIST_DIR/plasma-stats-${VERSION}.tar.gz"

rm -f "$PLASMOID_OUT" "$PLASMOID_LATEST" "$TARBALL_OUT"

(
    cd "$PKG_DIR"
    zip -r -q "$PLASMOID_OUT" .
)
cp "$PLASMOID_OUT" "$PLASMOID_LATEST"

tar -czf "$TARBALL_OUT" \
    -C "$ROOT_DIR" \
    package scripts README.md \
    "dist/${APPLET_ID}.plasmoid"

echo "Built packages:"
ls -lh "$PLASMOID_OUT" "$PLASMOID_LATEST" "$TARBALL_OUT"

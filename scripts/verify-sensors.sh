#!/usr/bin/env bash
set -euo pipefail

APPLET_ID="org.local.plasmastats"

echo "=== 1. Checking Plasma / kpackagetool6 installation ==="
if command -v kpackagetool6 >/dev/null 2>&1; then
    kpackagetool6 -t Plasma/Applet -s "$APPLET_ID" || echo "Not installed yet (run ./scripts/install.sh)"
else
    echo "kpackagetool6 not found"
fi

echo ""
echo "=== 2. Checking ksystemstats sensors (requires active Plasma/D-Bus session) ==="
if command -v kstatsviewer >/dev/null 2>&1; then
    echo "--- CPU sensors (sample) ---"
    kstatsviewer --list | grep -E "^cpu/(all|cpu0)/" | head -n 15 || true
    echo "--- GPU sensors (sample) ---"
    kstatsviewer --list | grep -E "^gpu/" | head -n 20 || true
    echo "--- Memory sensors (sample) ---"
    kstatsviewer --list | grep -E "^memory/" | head -n 15 || true
    echo "--- Network sensors (sample) ---"
    kstatsviewer --list | grep -E "^network/" | head -n 15 || true

    echo ""
    echo "--- Live sensor read test ---"
    kstatsviewer cpu/all/usage memory/physical/usedPercent network/all/download network/all/upload || true
else
    echo "kstatsviewer not found"
fi

echo ""
echo "=== 3. Standalone QML preview tip ==="
echo "To test the widget in a standalone window without restarting plasmashell:"
echo "  plasmawindowed $APPLET_ID"

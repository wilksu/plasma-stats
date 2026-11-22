#!/usr/bin/env bash
set -euo pipefail

APPLET_ID="org.local.plasmastats"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "Error: kpackagetool6 not found." >&2
    exit 1
fi

if kpackagetool6 -t Plasma/Applet -s "$APPLET_ID" >/dev/null 2>&1; then
    kpackagetool6 -t Plasma/Applet -r "$APPLET_ID"
    echo "Removed $APPLET_ID."
else
    echo "$APPLET_ID is not currently installed."
fi

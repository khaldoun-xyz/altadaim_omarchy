#!/bin/bash

# Show the active keyboard layout on the Omarchy lock screen placeholder.
# Updates ~/.config/hypr/hyprlock.conf
# Example: "Enter Password (German)" for kb_layout = de (QWERTZ)

set -euo pipefail

CONF="$HOME/.config/hypr/hyprlock.conf"
BACKUP="${CONF}.bak.$(date +%s)"
TARGET='placeholder_text = Enter Password ($LAYOUT)'

echo "🔧 Updating hyprlock to show keyboard layout in the password placeholder..."

if [[ ! -f "$CONF" ]]; then
    echo "Error: $CONF does not exist" >&2
    exit 1
fi

if grep -qF "$TARGET" "$CONF"; then
    echo "Already configured: $TARGET"
    exit 0
fi

cp "$CONF" "$BACKUP"
echo "Backup created: $BACKUP"

# Prefer replacing a plain "Enter Password" placeholder (with optional fingerprint markup)
if grep -qE '^\s*placeholder_text\s*=' "$CONF"; then
    sed -i 's|^\(\s*placeholder_text\s*=\s*\).*|\1Enter Password ($LAYOUT)|' "$CONF"
else
    echo "Error: no placeholder_text line found in $CONF" >&2
    cp "$BACKUP" "$CONF"
    exit 1
fi

if grep -qF "$TARGET" "$CONF"; then
    echo "Updated placeholder to show keyboard layout."
    echo "Takes effect the next time you lock the screen."
else
    echo "Error: Failed to update placeholder. Restoring backup." >&2
    cp "$BACKUP" "$CONF"
    exit 1
fi

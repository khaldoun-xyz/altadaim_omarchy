#!/bin/bash

# Set custom screenshot keybind to use region mode (mark box with mouse)
# Updates ~/.config/hypr/bindings.conf

set -e

CONF="$HOME/.config/hypr/bindings.conf"
BACKUP="${CONF}.bak.$(date +%s)"

if [[ ! -f "$CONF" ]]; then
    echo "Error: $CONF does not exist" >&2
    exit 1
fi

# Create backup
cp "$CONF" "$BACKUP"
echo "Backup created: $BACKUP"

# Check if SUPER SHIFT, S binding already exists
if grep -q '^bindd = SUPER SHIFT, S,' "$CONF"; then
    # Replace existing binding
    sed -i 's/^bindd = SUPER SHIFT, S,.*$/bindd = SUPER SHIFT, S, Screenshot region, exec, omarchy-cmd-screenshot region/' "$CONF"
    echo "Updated existing SUPER SHIFT+S keybind to use region mode."
else
    # Append new binding to end of file
    echo "" >> "$CONF"
    echo "bindd = SUPER SHIFT, S, Screenshot region, exec, omarchy-cmd-screenshot region" >> "$CONF"
    echo "Added new SUPER SHIFT+S keybind at end of file."
fi

# Verify the change
if grep -q 'bindd = SUPER SHIFT, S, Screenshot region, exec, omarchy-cmd-screenshot region' "$CONF"; then
    echo "Keybind set successfully."
    echo "Restart Hyprland or wait for auto-reload."
else
    echo "Error: Failed to set keybind. Restoring backup."
    cp "$BACKUP" "$CONF"
    exit 1
fi
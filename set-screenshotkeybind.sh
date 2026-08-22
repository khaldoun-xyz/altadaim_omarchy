#!/bin/bash
set -euo pipefail

# Set custom screenshot keybind to use region mode (mark box with mouse)
#
# Omarchy Quattro (4.x) moved Hyprland config to Lua: user overrides live in
# ~/.config/hypr/bindings.lua (sourced by hyprland.lua). In Quattro,
# SUPER+SHIFT+S is a default "Google Maps" webapp binding, so we unbind it
# first. Legacy Omarchy (<4) used ~/.config/hypr/bindings.conf instead.

HYPR_BINDINGS_LUA="$HOME/.config/hypr/bindings.lua"
HYPR_BINDINGS_CONF="$HOME/.config/hypr/bindings.conf"
changed=0

if [ -f "$HYPR_BINDINGS_LUA" ]; then
    if ! grep -q 'Screenshot region on SUPER+SHIFT+S' "$HYPR_BINDINGS_LUA"; then
        cp "$HYPR_BINDINGS_LUA" "$HYPR_BINDINGS_LUA.bak.$(date +%s)"
        cat >> "$HYPR_BINDINGS_LUA" <<'EOF'

-- Screenshot region on SUPER+SHIFT+S (no PRINT key on this keyboard)
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot region", "omarchy-capture-screenshot region")
EOF
        echo "Added SUPER+SHIFT+S region-screenshot keybind to $HYPR_BINDINGS_LUA"
        changed=1
    else
        echo "SUPER+SHIFT+S screenshot keybind already present in $HYPR_BINDINGS_LUA."
    fi
elif [ -f "$HYPR_BINDINGS_CONF" ]; then
    # Legacy Omarchy (<4): bindings.conf
    if grep -q '^bindd = SUPER SHIFT, S,' "$HYPR_BINDINGS_CONF"; then
        cp "$HYPR_BINDINGS_CONF" "$HYPR_BINDINGS_CONF.bak.$(date +%s)"
        sed -i 's/^bindd = SUPER SHIFT, S,.*$/bindd = SUPER SHIFT, S, Screenshot region, exec, omarchy-capture-screenshot region/' "$HYPR_BINDINGS_CONF"
        echo "Updated existing SUPER SHIFT+S keybind to use region mode in $HYPR_BINDINGS_CONF"
        changed=1
    else
        cp "$HYPR_BINDINGS_CONF" "$HYPR_BINDINGS_CONF.bak.$(date +%s)"
        echo "" >> "$HYPR_BINDINGS_CONF"
        echo "bindd = SUPER SHIFT, S, Screenshot region, exec, omarchy-capture-screenshot region" >> "$HYPR_BINDINGS_CONF"
        echo "Added SUPER SHIFT+S region-screenshot keybind to $HYPR_BINDINGS_CONF"
        changed=1
    fi
else
    echo "⚠️  Neither $HYPR_BINDINGS_LUA nor $HYPR_BINDINGS_CONF found."
    echo "   Add this to your Hyprland Lua config manually:"
    echo "   o.bind(\"SUPER + SHIFT + S\", \"Screenshot region\", \"omarchy-capture-screenshot region\")"
fi

if [ "$changed" -eq 1 ]; then
    hyprctl reload
    if hyprctl configerrors | grep -q .; then
        echo "⚠️  Hyprland config errors:" >&2
        hyprctl configerrors >&2
    fi
fi

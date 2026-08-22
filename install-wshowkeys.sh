#!/bin/bash
set -euo pipefail

# --- Install wshowkeys (DreamMaoMao fork) ---

# Remove any previously installed wshowkeys provider. This includes the -debug
# split packages, which a plain "wshowkeys wshowkeys-git" name check misses.
# Required because --noconfirm auto-declines pacman's "Remove ...? [y/N]" prompt.
conflicting=$(pacman -Q 2>/dev/null | awk '{print $1}' | grep -E '^(wshowkeys|wshowkeys-git|wshowkeys-git-debug)$' || true)
if [ -n "$conflicting" ]; then
    echo "Removing conflicting package(s): $conflicting"
    sudo pacman -Rns --noconfirm $conflicting
fi

if pacman -Q wshowkeys-mao-git >/dev/null 2>&1; then
    echo "wshowkeys-mao-git is already installed."
else
    # Prefer the package already built in the yay cache: a single, non-interactive
    # pacman -U (the interactive yay flow has been crashing the terminal on this
    # machine). Fall back to yay if the cache is empty (e.g. on a fresh setup).
    pkg=$(ls /home/s0288/.cache/yay/wshowkeys-mao-git/wshowkeys-mao-git-r*-x86_64.pkg.tar.zst 2>/dev/null | head -1 || true)
    if [ -n "$pkg" ]; then
        sudo pacman -U --noconfirm "$pkg"
    else
        if ! command -v yay >/dev/null 2>&1; then
            echo "❌ yay (AUR helper) not found and no cached package. Install yay first: https://aur.archlinux.org/packages/yay" >&2
            exit 1
        fi
        yay -S --needed --noconfirm wshowkeys-mao-git
    fi
fi

# --- Set up the 'showkeys' toggle command ---

SHOWKEYS_BIN="$HOME/.local/bin/showkeys"
if [ ! -f "$SHOWKEYS_BIN" ]; then
    cat > "$SHOWKEYS_BIN" <<'EOF'
#!/bin/bash
# Toggle the wshowkeys key-press overlay (anchored bottom).
# Note: -M/-U/-S enable the persistent modifier/mouse/scroll bar, which renders
# broken (giant, mid-screen) on scale-2 Hyprland 0.56, so it's intentionally
# omitted. The transient key chips above the bottom bar still show combos
# (e.g. "Shift+A").
if pgrep -x wshowkeys >/dev/null 2>&1; then
    pkill -x wshowkeys
else
    exec wshowkeys -a bottom
fi
EOF
    chmod +x "$SHOWKEYS_BIN"
    echo "Created $SHOWKEYS_BIN"
else
    echo "$SHOWKEYS_BIN already exists."
fi

# --- Bind CTRL+SUPER+^ to toggle the overlay ---
# SUPER+K was already taken by omarchy's "Show key bindings" (sourced default),
# so the toggle lives on CTRL+SUPER+^ (dead_circumflex on the German QWERTZ layout).

# Omarchy Quattro (4.x) moved Hyprland configuration to Lua files. User
# overrides live in ~/.config/hypr/bindings.lua (sourced by hyprland.lua);
# ~/.config/hypr/bindings.conf is only used by legacy Omarchy (<4).
HYPR_BINDINGS_LUA="$HOME/.config/hypr/bindings.lua"
HYPR_BINDINGS_CONF="$HOME/.config/hypr/bindings.conf"
changed=0

if [ -f "$HYPR_BINDINGS_LUA" ]; then
    if ! grep -q 'Show keys on screen (wshowkeys toggle)' "$HYPR_BINDINGS_LUA"; then
        cp "$HYPR_BINDINGS_LUA" "$HYPR_BINDINGS_LUA.bak.$(date +%s)"
        cat >> "$HYPR_BINDINGS_LUA" <<'EOF'

-- Show keys on screen (wshowkeys toggle)
o.bind("SUPER + CTRL + dead_circumflex", "Show keys", "showkeys")
EOF
        echo "Added CTRL+SUPER+^ hotkey to $HYPR_BINDINGS_LUA"
        changed=1
    else
        echo "CTRL+SUPER+^ hotkey already present in $HYPR_BINDINGS_LUA."
    fi
elif [ -f "$HYPR_BINDINGS_CONF" ]; then
    # Legacy Omarchy (<4): bindings.conf
    if grep -q 'exec, showkeys' "$HYPR_BINDINGS_CONF"; then
        echo "CTRL+SUPER+^ hotkey already present in $HYPR_BINDINGS_CONF."
    else
        cp "$HYPR_BINDINGS_CONF" "$HYPR_BINDINGS_CONF.bak.$(date +%s)"
        cat >> "$HYPR_BINDINGS_CONF" <<'EOF'

# Show keys on screen (wshowkeys toggle)
bindd = SUPER CTRL, dead_circumflex, Show keys, exec, showkeys
EOF
        echo "Added CTRL+SUPER+^ hotkey to $HYPR_BINDINGS_CONF"
        changed=1
    fi
else
    echo "⚠️  Neither $HYPR_BINDINGS_LUA nor $HYPR_BINDINGS_CONF found."
    echo "   Add this line to your Hyprland Lua config manually:"
    echo "   o.bind(\"SUPER + CTRL + dead_circumflex\", \"Show keys\", \"showkeys\")"
fi

if [ "$changed" -eq 1 ]; then
    hyprctl reload
    if hyprctl configerrors | grep -q .; then
        echo "⚠️  Hyprland config errors after adding the binding:" >&2
        hyprctl configerrors >&2
    fi
fi

echo "✨ Wshowkeys installed. Run 'showkeys' or press CTRL+SUPER+^ to toggle the key display."

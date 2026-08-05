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
# Toggle the wshowkeys key-press overlay.
# Modifier keys (-M), mouse buttons (-U), scroll direction (-S), anchored bottom.
if pgrep -x wshowkeys >/dev/null 2>&1; then
    pkill -x wshowkeys
else
    exec wshowkeys -a bottom -M -U -S
fi
EOF
    chmod +x "$SHOWKEYS_BIN"
    echo "Created $SHOWKEYS_BIN"
else
    echo "$SHOWKEYS_BIN already exists."
fi

# --- Bind SUPER+^ to toggle the overlay ---
# SUPER+K was already taken by omarchy's "Show key bindings" (sourced default),
# so the toggle lives on SUPER+^ (dead_circumflex on the German QWERTZ layout).

HYPR_BINDINGS="$HOME/.config/hypr/bindings.conf"
if [ -f "$HYPR_BINDINGS" ]; then
    changed=0
    # Migrate away from earlier binding forms if present
    if grep -qE 'SUPER, K, Show keys|, dead_circumflex, Show keys' "$HYPR_BINDINGS"; then
        cp "$HYPR_BINDINGS" "$HYPR_BINDINGS.bak.$(date +%s)"
        sed -i -E '/SUPER, K, Show keys|, dead_circumflex, Show keys/d' "$HYPR_BINDINGS"
        echo "Removed old showkeys binding(s)."
        changed=1
    fi
    if ! grep -q 'exec, showkeys' "$HYPR_BINDINGS"; then
        [ "$changed" -eq 0 ] && cp "$HYPR_BINDINGS" "$HYPR_BINDINGS.bak.$(date +%s)"
        cat >> "$HYPR_BINDINGS" <<'EOF'

# Show keys on screen (wshowkeys toggle)
bindd = SUPER, dead_circumflex, Show keys, exec, showkeys
EOF
        echo "Added SUPER+^ hotkey to $HYPR_BINDINGS"
        changed=1
    fi
    if [ "$changed" -eq 1 ]; then
        hyprctl reload
        if hyprctl configerrors | grep -q .; then
            echo "⚠️  Hyprland config errors after adding the binding:" >&2
            hyprctl configerrors >&2
        fi
    fi
fi

echo "✨ Wshowkeys installed. Run 'showkeys' or press SUPER+^ to toggle the key display."

#!/bin/bash
yay -S --noconfirm brave-bin

# Set Brave as the default browser (run as user, not sudo)
xdg-settings set default-web-browser brave-browser.desktop
xdg-mime default brave-browser.desktop x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml

echo "✨ Brave Browser installed and set as default."

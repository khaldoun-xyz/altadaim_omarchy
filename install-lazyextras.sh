#!/bin/bash

yay -S --noconfirm --needed jq

CONFIG_FILE="$HOME/.config/nvim/lazyvim.json"
EXTRAS=(
  "lazyvim.plugins.extras.lang.markdown"
  "lazyvim.plugins.extras.lang.python"
)

[ ! -f "$CONFIG_FILE" ] && echo '{"extras": []}' > "$CONFIG_FILE"
tmp=$(mktemp)
jq '.extras = (.extras + $ARGS.positional) | .extras |= unique' \
   "$CONFIG_FILE" --args "${EXTRAS[@]}" > "$tmp" && mv "$tmp" "$CONFIG_FILE"

echo "✨ LazyVim Extras installed."

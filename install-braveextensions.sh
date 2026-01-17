#!/bin/bash

POLICY_DIR="/etc/brave/policies/managed"
POLICY_FILE="$POLICY_DIR/managed_extensions.json"

UNHOOK_ID="iniiidjgbmhddeaoblbjoopnmlfnhelf"
VIMIUM_ID="dbepggeogbaibhgnhhndojpepiihcmeb"

UPDATE_URL="https://clients2.google.com/service/update2/crx"

echo "⚙️  Configuring Brave to silently install AND PIN extensions..."

sudo mkdir -p "$POLICY_DIR"

cat <<EOF | sudo tee "$POLICY_FILE" > /dev/null
{
  "ExtensionSettings": {
    "$UNHOOK_ID": {
      "installation_mode": "force_installed",
      "update_url": "$UPDATE_URL",
      "toolbar_pin": "force_pinned"
    },
    "$VIMIUM_ID": {
      "installation_mode": "force_installed",
      "update_url": "$UPDATE_URL",
      "toolbar_pin": "force_pinned"
    }
  }
}
EOF

echo "✅ Policy created at $POLICY_FILE"
echo "🔄 Restart Brave. The extensions will install and be pinned automatically."

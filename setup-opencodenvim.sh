#!/bin/bash
set -euo pipefail

PLUGIN_FILE="$HOME/.config/nvim/lua/plugins/opencode.lua"

echo "📝 configuring opencode.nvim (Official Config)..."

cat <<EOF > "$PLUGIN_FILE"
return {
  {
    "NickvanDyke/opencode.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function()
      -- 1. Set Options
      vim.g.opencode_opts = {}
      vim.o.autoread = true -- Required for reload events

      -- 2. Keymaps
      local oc = require("opencode")

      -- Core Actions
      vim.keymap.set({ "n", "x" }, "<leader>oa", function() oc.ask("@this: ", { submit = true }) end, { desc = "Ask opencode..." })
      vim.keymap.set({ "n", "x" }, "<leader>ox", function() oc.select() end,                          { desc = "Execute opencode action..." })
      vim.keymap.set({ "n", "t" }, "<leader>oo", function() oc.toggle() end,                          { desc = "Toggle opencode" })
    end,
  },
}
EOF

echo "✅ OpenCode plugin installed. Restart Neovim."

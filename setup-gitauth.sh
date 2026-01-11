#!/bin/bash
set -e

echo "🔧 Starting Git & SSH Setup..."

# --- 1. Git Configuration ---
echo ""
echo "--- Step 1: Git Identity ---"

# Ask for Name
read -p "Enter your Full Name (for Git commits): " GIT_NAME
git config --global user.name "$GIT_NAME"

# Ask for Email
read -p "Enter your Email (for Git commits & SSH key label): " GIT_EMAIL
git config --global user.email "$GIT_EMAIL"

echo "✅ Git config updated."

# --- 2. SSH Key Generation ---
echo ""
echo "--- Step 2: SSH Key Generation ---"
SSH_KEY="$HOME/.ssh/id_ed25519"

if [ -f "$SSH_KEY" ]; then
    echo "⚠️  An SSH key already exists at $SSH_KEY"
    read -p "Do you want to overwrite it? (This will break existing access) [y/N] " overwrite
    if [[ $overwrite =~ ^[Yy]$ ]]; then
        rm "$SSH_KEY" "$SSH_KEY.pub"
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY"
        echo "✅ New key generated."
    else
        echo "✅ Using existing key."
    fi
else
    # Generate new key
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY"
    echo "✅ Key generated."
fi

# --- 3. GitHub Handover ---
echo ""
echo "--- Step 3: Add to GitHub ---"
echo "--------------------------------------------------------"
echo "👇 COPY THE KEY BELOW 👇"
echo "--------------------------------------------------------"
cat "$SSH_KEY.pub"
echo "--------------------------------------------------------"

echo "Opening GitHub Settings in your browser..."
# Try to open the browser; fail silently if not found
xdg-open "https://github.com/settings/ssh/new" 2>/dev/null || echo "Could not open browser. Please visit: https://github.com/settings/ssh/new"

echo ""
echo "Instructions:"
echo "1. Paste the key above into the 'Key' field on GitHub."
echo "2. Give it a title (e.g. 'Omarchy Laptop')."
echo "3. Click 'Add SSH Key'."

read -p "👉 Press [Enter] once you have finished adding the key to GitHub..."

#!/bin/bash
set -euo pipefail

# Install cronie so the `crontab` command is available.
sudo pacman -S --needed --noconfirm cronie

# Enable and start the cron daemon so scheduled jobs actually run.
sudo systemctl enable --now cronie.service

echo "✨ cronie installed and running."
echo "   List jobs with 'crontab -l', edit them with 'crontab -e'."

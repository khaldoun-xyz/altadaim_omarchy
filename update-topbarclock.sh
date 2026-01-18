#!/bin/bash

# Script to add quarter countdown functionality to Waybar clock
# Replaces built-in clock module with custom two-state module:
# State 0: Time and date (HH:MM DD.MM.YY Www)
# State 1: Quarter countdown (X days, Y hours, Z minutes)

set -euo pipefail

echo "🔧 Setting up quarter countdown clock for Omarchy..."

OMARCHY_SCRIPTS_DIR="$HOME/.config/omarchy/scripts"
OMARCHY_STATE_DIR="$HOME/.config/omarchy/state"
WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"
BACKUP_CONFIG="$HOME/.config/waybar/config.jsonc.backup.$(date +%s)"

mkdir -p "$OMARCHY_SCRIPTS_DIR"
mkdir -p "$OMARCHY_STATE_DIR"

echo "📝 Creating quarter countdown script..."
cat > "$OMARCHY_SCRIPTS_DIR/quarter-countdown.sh" << 'QUARTER_EOF'
#!/bin/bash

# Calculate time remaining until end of current calendar quarter
# Quarters: Q1 (Jan-Mar), Q2 (Apr-Jun), Q3 (Jul-Sep), Q4 (Oct-Dec)
# Quarter ends: Mar 31, Jun 30, Sep 30, Dec 31 at 23:59:59
# Output format: "X days, Y hours, Z minutes" (rounded down)

get_current_month() {
    date +%m | sed 's/^0//'
}

get_current_year() {
    date +%Y
}

get_quarter_end() {
    local month=$1
    local year=$2
    
    case $month in
        1|2|3)
            echo "${year}-03-31 23:59:59"
            ;;
        4|5|6)
            echo "${year}-06-30 23:59:59"
            ;;
        7|8|9)
            echo "${year}-09-30 23:59:59"
            ;;
        10|11|12)
            echo "${year}-12-31 23:59:59"
            ;;
        *)
            echo "Error: Invalid month $month" >&2
            exit 1
            ;;
    esac
}

main() {
    local month=$(get_current_month)
    local year=$(get_current_year)
    local quarter_end=$(get_quarter_end "$month" "$year")
    
    # Convert quarter end to Unix timestamp
    local end_timestamp
    if ! end_timestamp=$(date -d "$quarter_end" +%s 2>/dev/null); then
        # Fallback for macOS/BSD date compatibility
        end_timestamp=$(date -j -f "%Y-%m-%d %H:%M:%S" "$quarter_end" +%s 2>/dev/null || echo 0)
    fi
    
    local current_timestamp=$(date +%s)
    
    if (( end_timestamp <= current_timestamp )); then
        # Quarter has ended or is ending now
        echo "0 days, 0 hours, 0 minutes"
        return 0
    fi
    
    local seconds_remaining=$((end_timestamp - current_timestamp))
    
    # Calculate days, hours, minutes (rounded down)
    local days=$((seconds_remaining / 86400))
    local hours=$(((seconds_remaining % 86400) / 3600))
    local minutes=$(((seconds_remaining % 3600) / 60))
    
    echo "${days} days, ${hours} hours, ${minutes} minutes"
}

main "$@"
QUARTER_EOF

# Create clock cycle state management script
echo "📝 Creating clock cycle script..."
cat > "$OMARCHY_SCRIPTS_DIR/clock-cycle.sh" << 'CLOCK_EOF'
#!/bin/bash

# Stateful clock module for Waybar
# State 0: Time and date (HH:MM DD.MM.YY Www)
# State 1: Quarter countdown
# Toggle state with: ./clock-cycle.sh toggle
# Outputs JSON for Waybar custom module

STATE_FILE="$HOME/.config/omarchy/state/clock-state"
QUARTER_SCRIPT="$HOME/.config/omarchy/scripts/quarter-countdown.sh"

# Ensure state file exists with default value
ensure_state_file() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "0" > "$STATE_FILE"
    fi
}

# Read current state (0 or 1)
read_state() {
    ensure_state_file
    local state
    if ! state=$(cat "$STATE_FILE" 2>/dev/null); then
        state="0"
    fi
    
    # Validate state value
    if [[ "$state" != "0" && "$state" != "1" ]]; then
        state="0"
        echo "$state" > "$STATE_FILE"
    fi
    
    echo "$state"
}

# Write new state
write_state() {
    local state=$1
    echo "$state" > "$STATE_FILE"
}

# Toggle state (0→1, 1→0)
toggle_state() {
    local current_state=$(read_state)
    local new_state
    if [[ "$current_state" == "0" ]]; then
        new_state="1"
    else
        new_state="0"
    fi
    write_state "$new_state"
    echo "$new_state"
}

# Get display text for current state
get_display_text() {
    local state=$1
    
    case "$state" in
        0)
            # Time and date: "00:04 18.01.26 W03"
            date +"%H:%M %d.%m.%y W%V"
            ;;
        1)
            # Quarter countdown
            if [[ -x "$QUARTER_SCRIPT" ]]; then
                "$QUARTER_SCRIPT"
            else
                echo "Error: quarter script missing"
            fi
            ;;
        *)
            date +"%H:%M %d.%m.%y W%V"
            ;;
    esac
}

# Main execution
main() {
    # Handle toggle command
    if [[ "$1" == "toggle" ]]; then
        toggle_state >/dev/null
        # After toggle, read new state for display
        local state=$(read_state)
        local text=$(get_display_text "$state")
        echo "{\"text\": \"$text\"}"
        return 0
    fi
    
    # Normal execution: output JSON for current state
    local state=$(read_state)
    local text=$(get_display_text "$state")
    echo "{\"text\": \"$text\"}"
}

main "$@"
CLOCK_EOF

chmod +x "$OMARCHY_SCRIPTS_DIR/quarter-countdown.sh"
chmod +x "$OMARCHY_SCRIPTS_DIR/clock-cycle.sh"
cp "$WAYBAR_CONFIG" "$BACKUP_CONFIG"

if grep -q '"custom/clock"' "$WAYBAR_CONFIG"; then
    echo "⚠️  Custom clock already configured in Waybar. Skipping config modification."
else
    echo "⚙️  Modifying Waybar configuration..."
    
    TMP_CONFIG=$(mktemp)
    
    # Use awk for robust JSONC manipulation
    awk -v home="$HOME" '
    BEGIN { in_clock_block = 0; }
    
    # Replace "clock" with "custom/clock" in modules-center array
    /"modules-center":/ && /"clock"/ {
        # Replace first occurrence of "clock" with "custom/clock"
        sub(/"clock"/, "\"custom/clock\"")
        print $0
        next
    }
    
    # Detect start of clock config block
    /"clock": {/ {
        in_clock_block = 1
        # Replace with custom clock config
        print "  \"custom/clock\": {"
        print "    \"exec\": \"" home "/.config/omarchy/scripts/clock-cycle.sh\","
        print "    \"exec-if\": \"test -x " home "/.config/omarchy/scripts/clock-cycle.sh\","
        print "    \"on-click\": \"" home "/.config/omarchy/scripts/clock-cycle.sh toggle && pkill -RTMIN+9 waybar\","
        print "    \"on-click-right\": \"omarchy-launch-floating-terminal-with-presentation omarchy-tz-select\","
        print "    \"return-type\": \"json\","
        print "    \"signal\": 9,"
        print "    \"interval\": 60"
        print "  },"
        next
    }
    
    # Skip lines inside the original clock block
    in_clock_block {
        # Check if this line ends the clock block (with optional comma, allowing comments after)
        if ($0 ~ /^[[:space:]]*},?/) {
            in_clock_block = 0
        }
        next
    }
    
    # Print all other lines
    {
        print $0
    }
    ' "$WAYBAR_CONFIG" > "$TMP_CONFIG"
    
    if ! grep -q '"custom/clock"' "$TMP_CONFIG"; then
        echo "❌ Failed to add custom/clock to config. Trying alternative approach..."
        
        # Alternative approach: simple sed for modules-center
        cp "$BACKUP_CONFIG" "$TMP_CONFIG"
        sed -i 's/"clock",/"custom\/clock",/g' "$TMP_CONFIG"
        sed -i 's/"clock"]/"custom\/clock"]/g' "$TMP_CONFIG"
        
        # Remove old clock config block (more flexible pattern for indentation)
        sed -i '/"clock": {/,/^[[:space:]]*},/d' "$TMP_CONFIG"
        sed -i '/"clock": {/,/^[[:space:]]*}/d' "$TMP_CONFIG"
        
        # Add custom clock config before the cpu section
        CUSTOM_CLOCK_CONFIG="  \"custom/clock\": {\n    \"exec\": \"$HOME/.config/omarchy/scripts/clock-cycle.sh\",\n    \"exec-if\": \"test -x $HOME/.config/omarchy/scripts/clock-cycle.sh\",\n    \"on-click\": \"$HOME/.config/omarchy/scripts/clock-cycle.sh toggle && pkill -RTMIN+9 waybar\",\n    \"on-click-right\": \"omarchy-launch-floating-terminal-with-presentation omarchy-tz-select\",\n    \"return-type\": \"json\",\n    \"signal\": 9,\n    \"interval\": 60\n  },"
        
        # Insert before cpu section, or if not found, before network section
        if grep -q '"cpu": {' "$TMP_CONFIG"; then
            sed -i '/"cpu": {/i\'"$CUSTOM_CLOCK_CONFIG" "$TMP_CONFIG"
        elif grep -q '"network": {' "$TMP_CONFIG"; then
            sed -i '/"network": {/i\'"$CUSTOM_CLOCK_CONFIG" "$TMP_CONFIG"
        else
            # Append before the final closing brace
            sed -i '$i\'"$CUSTOM_CLOCK_CONFIG" "$TMP_CONFIG"
        fi
    fi
    
    if grep -q '"custom/clock"' "$TMP_CONFIG"; then
        mv "$TMP_CONFIG" "$WAYBAR_CONFIG"
        echo "✅ Waybar configuration updated successfully."
    else
        echo "❌ Failed to update Waybar configuration. Restoring backup..."
        mv "$BACKUP_CONFIG" "$WAYBAR_CONFIG"
        rm -f "$TMP_CONFIG"
        exit 1
    fi
fi

echo "🔄 Restarting Waybar..."
if command -v omarchy-restart-waybar >/dev/null 2>&1; then
    omarchy-restart-waybar
    echo "✅ Waybar restarted successfully."
else
    echo "⚠️  Could not find omarchy-restart-waybar command."
    echo "   Please restart Waybar manually to apply changes."
fi

echo ""
echo "✨ Quarter countdown clock setup complete!"
echo ""
echo "How to use:"
echo "  - Click the clock to toggle between time/date and quarter countdown"
echo "  - Right-click the clock to change timezone (existing functionality)"
echo ""
echo "Clock states:"
echo "  State 0: Time and date (e.g., '00:04 18.01.26 W03')"
echo "  State 1: Quarter countdown (e.g., '72 days, 23 hours, 54 minutes')"
echo ""
echo "Note: Countdown updates every minute."

#!/bin/bash
set -e
# install-pi.sh
# Installs pi (coding agent) and adds DeepSeek as a custom model.
# The API key is read from the environment variable DEEPSEEK_API_KEY,
# which should be set in your shell config (e.g., ~/.bashrc).

echo "🔧 Installing pi coding agent..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if jq is installed (required for config merging)
if ! command -v jq &> /dev/null; then
    echo "❌ jq is not installed. Please install jq first (e.g., 'sudo pacman -S jq')."
    exit 1
fi

# Install pi globally via npm
if ! command -v pi &> /dev/null; then
    echo "📦 pi not found, installing via npm..."
    npm install -g @mariozechner/pi-coding-agent
    echo "✅ pi installed globally."
else
    echo "✅ pi already installed ($(which pi))."
fi

# Ensure pi config directory exists
PI_CONFIG_DIR="$HOME/.pi/agent"
mkdir -p "$PI_CONFIG_DIR"

# Path to models.json
MODELS_JSON="$PI_CONFIG_DIR/models.json"

# DeepSeek provider configuration
DEEPSEEK_PROVIDER=$(cat <<'EOF'
{
  "deepseek": {
    "baseUrl": "https://api.deepseek.com",
    "api": "openai-completions",
    "apiKey": "DEEPSEEK_API_KEY",
    "compat": {
      "supportsDeveloperRole": false,
      "supportsReasoningEffort": false,
      "supportsStore": false,
      "supportsUsageInStreaming": true,
      "maxTokensField": "max_completion_tokens",
      "requiresToolResultName": false,
      "requiresAssistantAfterToolResult": false,
      "requiresThinkingAsText": false,
      "thinkingFormat": "openai",
      "supportsStrictMode": true
    },
    "models": [
      {
        "id": "deepseek-reasoner",
        "name": "DeepSeek Reasoner",
        "reasoning": true,
        "input": ["text"],
        "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
        "contextWindow": 128000,
        "maxTokens": 32000
      },
      {
        "id": "deepseek-chat",
        "name": "DeepSeek Chat",
        "reasoning": false,
        "input": ["text"],
        "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
        "contextWindow": 128000,
        "maxTokens": 32000
      },
      {
        "id": "deepseek-coder",
        "name": "DeepSeek Coder",
        "reasoning": false,
        "input": ["text"],
        "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
        "contextWindow": 128000,
        "maxTokens": 32000
      }
    ]
  }
}
EOF
)

# Ensure deepseek provider exists in models.json
if [ -f "$MODELS_JSON" ]; then
    echo "📄 Found existing $MODELS_JSON, checking DeepSeek provider..."
    # Check if file is empty
    if [ ! -s "$MODELS_JSON" ]; then
        echo "⚠️  models.json is empty. Creating new."
        echo "{\"providers\": $DEEPSEEK_PROVIDER}" > "$MODELS_JSON"
        echo "✅ Created new models.json with DeepSeek provider."
    # Validate JSON and backup if corrupted
    elif ! jq empty "$MODELS_JSON" 2>/dev/null; then
        echo "⚠️  models.json is not valid JSON. Creating backup and new file."
        mv "$MODELS_JSON" "$MODELS_JSON.backup.$(date +%s)"
        echo "{\"providers\": $DEEPSEEK_PROVIDER}" > "$MODELS_JSON"
        echo "✅ Created new models.json with DeepSeek provider."
    else
        # Valid JSON
        if jq -e '.providers.deepseek' "$MODELS_JSON" > /dev/null 2>&1; then
            echo "✅ DeepSeek provider already exists."
            # Optionally ensure apiKey is DEEPSEEK_API_KEY
            CURRENT_APIKEY=$(jq -r '.providers.deepseek.apiKey // ""' "$MODELS_JSON")
            if [[ "$CURRENT_APIKEY" != "DEEPSEEK_API_KEY" ]]; then
                echo "⚠️  DeepSeek provider's apiKey is '$CURRENT_APIKEY', updating to DEEPSEEK_API_KEY..."
                jq '.providers.deepseek.apiKey = "DEEPSEEK_API_KEY"' "$MODELS_JSON" > "$MODELS_JSON.tmp" && mv "$MODELS_JSON.tmp" "$MODELS_JSON"
                echo "✅ Updated apiKey."
            fi
        else
            echo "➕ Adding DeepSeek provider to existing models.json..."
            # Use jq to add the deepseek provider
            if jq --argjson new "$DEEPSEEK_PROVIDER" '.providers *= $new' "$MODELS_JSON" > "$MODELS_JSON.tmp"; then
                mv "$MODELS_JSON.tmp" "$MODELS_JSON"
                echo "✅ DeepSeek provider added."
            else
                echo "❌ Failed to add provider with jq."
                exit 1
            fi
        fi
    fi
else
    echo "📄 Creating new $MODELS_JSON with DeepSeek provider..."
    echo "{\"providers\": $DEEPSEEK_PROVIDER}" > "$MODELS_JSON"
    echo "✅ Created models.json with DeepSeek provider."
fi

# Check if DEEPSEEK_API_KEY is set in environment
if [ -z "${DEEPSEEK_API_KEY:-}" ]; then
    echo "⚠️  DEEPSEEK_API_KEY environment variable is not set in the current shell."
    # Check shell config files for the variable
    found_in_file=""
    for rcfile in ~/.bashrc ~/.zshrc ~/.profile ~/.bash_profile; do
        if [ -f "$rcfile" ] && grep -q "export DEEPSEEK_API_KEY=" "$rcfile" 2>/dev/null; then
            found_in_file="$rcfile"
            break
        fi
    done
    if [ -n "$found_in_file" ]; then
        echo "   Found export in $found_in_file. You may need to restart your shell or run:"
        echo "      source $found_in_file"
    else
        echo "🔧 Adding DEEPSEEK_API_KEY export to ~/.bashrc ..."
        if ! grep -q "export DEEPSEEK_API_KEY=" ~/.bashrc; then
            echo "" >> ~/.bashrc
            echo "# DeepSeek API key" >> ~/.bashrc
            echo "export DEEPSEEK_API_KEY='YOUR API KEY'" >> ~/.bashrc
        fi
        echo "   Please replace 'YOUR API KEY' with your actual DeepSeek API key."
    fi
else
    echo "✅ DEEPSEEK_API_KEY is set in environment."
fi

echo ""
echo "✨ pi installation complete!"
echo "   To start pi, just type 'pi' in your terminal."
echo "   Select DeepSeek models via '/model' command."
echo ""
echo "   Note: pi will read the API key from the DEEPSEEK_API_KEY environment variable."
echo "   Ensure the variable is exported in your shell before running pi."
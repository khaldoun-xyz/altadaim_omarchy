#!/bin/bash

PSQLRC_PATH="$HOME/.psqlrc"

if [[ -f "$PSQLRC_PATH" ]]; then
    echo "⚠️  Existing .psqlrc found at $PSQLRC_PATH (will be overwritten)"
fi

cat > "$PSQLRC_PATH" << 'EOF'
\set QUIET 1
\pset border 2
\pset linestyle unicode
\pset null 'NULL'
\x auto
\set QUIET 0
EOF

echo "✨ .psqlrc created at $PSQLRC_PATH"
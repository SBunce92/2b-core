#!/bin/bash
# Stop Hook: Auto-capture significant exchanges to log
# Deterministic - doesn't rely on Claude to act

VAULT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$VAULT_DIR/log"
WEEK=$(date +%Y-W%V)
LOG_FILE="$LOG_DIR/$WEEK.md"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

# Read hook input (JSON with conversation data)
INPUT=$(cat)

# Extract last assistant message
LAST_RESPONSE=$(echo "$INPUT" | jq -r '.messages[-1].content // empty' 2>/dev/null)

# Skip if no response or too short
if [ -z "$LAST_RESPONSE" ] || [ ${#LAST_RESPONSE} -lt 200 ]; then
    exit 0
fi

# Detect significance
HAS_CODE=$(echo "$LAST_RESPONSE" | grep -c '```' || echo 0)
HAS_DECISION=$(echo "$LAST_RESPONSE" | grep -ciE '(decided|decision|will |agreed|conclusion|recommend)' || echo 0)
WORD_COUNT=$(echo "$LAST_RESPONSE" | wc -w | tr -d ' ')

# Capture if significant
if [ "$HAS_CODE" -gt 0 ] || [ "$HAS_DECISION" -gt 0 ] || [ "$WORD_COUNT" -gt 500 ]; then
    # Get user's question for context
    LAST_USER=$(echo "$INPUT" | jq -r '.messages[-2].content // ""' 2>/dev/null)

    # Truncate user message if too long
    if [ ${#LAST_USER} -gt 300 ]; then
        LAST_USER="${LAST_USER:0:300}..."
    fi

    # Truncate response if extremely long (>5000 chars)
    if [ ${#LAST_RESPONSE} -gt 5000 ]; then
        LAST_RESPONSE="${LAST_RESPONSE:0:5000}

[... truncated, ${#LAST_RESPONSE} chars total ...]"
    fi

    mkdir -p "$LOG_DIR"

    # Append full exchange to log
    cat >> "$LOG_FILE" << CAPTURE_EOF

## $TIMESTAMP | Auto-Capture

**User:** $LAST_USER

**Response:**
$LAST_RESPONSE

---
CAPTURE_EOF

    echo "[Captured to $WEEK.md]"
fi

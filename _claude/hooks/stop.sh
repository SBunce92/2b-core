#!/bin/bash
# Stop Hook: Queue significant exchanges for AI summarization
# Queues to pending file - processed by 'cc --digest' or next session

VAULT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PENDING_FILE="$VAULT_DIR/_state/pending-captures.jsonl"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

# Read hook input
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

# Queue if significant
if [ "$HAS_CODE" -gt 0 ] || [ "$HAS_DECISION" -gt 0 ] || [ "$WORD_COUNT" -gt 500 ]; then
    LAST_USER=$(echo "$INPUT" | jq -r '.messages[-2].content // ""' 2>/dev/null)

    # Truncate for queue (full content too large)
    LAST_USER=$(echo "$LAST_USER" | head -c 500)
    LAST_RESPONSE=$(echo "$LAST_RESPONSE" | head -c 3000)

    mkdir -p "$(dirname "$PENDING_FILE")"

    # Append to pending queue as JSON line
    jq -n --arg ts "$TIMESTAMP" \
          --arg user "$LAST_USER" \
          --arg response "$LAST_RESPONSE" \
          --arg trigger "$([ "$HAS_CODE" -gt 0 ] && echo "code ")$([ "$HAS_DECISION" -gt 0 ] && echo "decision ")$([ "$WORD_COUNT" -gt 500 ] && echo "long")" \
          '{timestamp: $ts, user: $user, response: $response, trigger: $trigger}' >> "$PENDING_FILE"

    PENDING_COUNT=$(wc -l < "$PENDING_FILE" 2>/dev/null | tr -d ' ')
    echo "[Queued for digest - $PENDING_COUNT pending]"
fi

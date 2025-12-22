#!/bin/bash
# Stop Hook: Queue all exchanges for AI capture
# Capture agent decides significance, not bash heuristics

VAULT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PENDING_FILE="$VAULT_DIR/_state/pending-captures.jsonl"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

# Read hook input (contains transcript_path, not messages directly)
INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Exit if no transcript
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    exit 0
fi

# Get last messages from transcript (JSONL format)
# Assistant: find last message that actually has text content (skip tool-only)
# User: find last message where content is string (skip tool_result)
LAST_RESPONSE=$(grep '"type":"assistant"' "$TRANSCRIPT_PATH" | jq -r 'select(.message.content[] | .type=="text") | .message.content[] | select(.type=="text") | .text' 2>/dev/null | tail -1)
LAST_USER=$(grep '"type":"user"' "$TRANSCRIPT_PATH" | jq -r 'select(.message.content | type=="string") | .message.content' 2>/dev/null | tail -1)

# Skip if no response
if [ -z "$LAST_RESPONSE" ]; then
    exit 0
fi

# Truncate for queue (prevent context bloat)
LAST_USER=$(echo "$LAST_USER" | head -c 500)
LAST_RESPONSE=$(echo "$LAST_RESPONSE" | head -c 3000)

mkdir -p "$(dirname "$PENDING_FILE")"

# Append to pending queue (compact JSON, one line per entry)
jq -c -n --arg ts "$TIMESTAMP" \
      --arg user "$LAST_USER" \
      --arg response "$LAST_RESPONSE" \
      '{timestamp: $ts, user: $user, response: $response}' >> "$PENDING_FILE"

PENDING_COUNT=$(wc -l < "$PENDING_FILE" 2>/dev/null | tr -d ' ')
echo "[Queued - $PENDING_COUNT pending]"

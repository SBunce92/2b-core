#!/bin/bash
# UserPromptSubmit Hook: Inject pending captures for AI summarization
# stdout gets added to Claude's context before processing user prompt

VAULT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PENDING_FILE="$VAULT_DIR/_state/pending-captures.jsonl"
PROCESSING_FILE="$VAULT_DIR/_state/processing-captures.jsonl"

# Check if pending captures exist
if [ ! -f "$PENDING_FILE" ] || [ ! -s "$PENDING_FILE" ]; then
    exit 0
fi

# Count pending
PENDING_COUNT=$(wc -l < "$PENDING_FILE" 2>/dev/null | tr -d ' ')
if [ "$PENDING_COUNT" -eq 0 ]; then
    exit 0
fi

# Move to processing (atomic)
mv "$PENDING_FILE" "$PROCESSING_FILE" 2>/dev/null || exit 0

# Read pending captures (limit to 3 most recent to avoid context bloat)
CAPTURES=$(tail -3 "$PROCESSING_FILE" | jq -s '.')

# Inject instruction for Claude (appears in context)
cat << 'EOF'
<user-prompt-submit-hook>
IMPORTANT: Before responding to the user's prompt, you MUST first process the pending captures below.

Use the Task tool with subagent_type="capture" to summarize these exchanges and append to the weekly log.

Pending captures to process:
EOF

# Output captures
echo "$CAPTURES" | jq -r '.[] | "---\nTimestamp: \(.timestamp)\nTrigger: \(.trigger)\nUser: \(.user)\nResponse: \(.response[0:1500])...\n"'

cat << 'EOF'

After spawning the capture agent, continue with the user's actual request.
</user-prompt-submit-hook>
EOF

# Clean up processing file after injection
rm -f "$PROCESSING_FILE" 2>/dev/null

exit 0

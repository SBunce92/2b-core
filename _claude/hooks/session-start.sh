#!/bin/bash
# SessionStart Hook: Inject recent log context
#
# Output is added to Claude's context at session start.

VAULT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$VAULT_DIR/log"
CURRENT_WEEK=$(date +%Y-W%V)
CURRENT_LOG="$LOG_DIR/$CURRENT_WEEK.md"
ERROR_LOG="$VAULT_DIR/_state/hook-errors.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

# Error logging helper
log_error() {
    mkdir -p "$(dirname "$ERROR_LOG")"
    echo "[$TIMESTAMP] [session-start] $1" >> "$ERROR_LOG"
}

echo "## Recent Context"
echo ""

# Show recent log entries
if [ -f "$CURRENT_LOG" ]; then
    echo "### This Week ($CURRENT_WEEK)"
    echo ""
    # Last 40 lines of current week
    tail -40 "$CURRENT_LOG" 2>/dev/null
    echo ""
else
    echo "No log entries yet this week."
    echo ""
fi

echo "---"
echo ""
echo "**Capture**: After significant exchanges, spawn the capture agent to save insights."
echo "**Log file**: log/$CURRENT_WEEK.md"
echo ""

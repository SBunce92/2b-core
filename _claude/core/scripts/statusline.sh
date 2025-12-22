#!/bin/bash
# Status line for Claude Code
# Shows context window usage

input=$(cat)

# Extract context window data
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
USAGE=$(echo "$input" | jq -r '.context_window.current_usage // empty')

if [ -n "$USAGE" ] && [ "$USAGE" != "null" ]; then
    INPUT_TOKENS=$(echo "$USAGE" | jq -r '.input_tokens // 0')
    OUTPUT_TOKENS=$(echo "$USAGE" | jq -r '.output_tokens // 0')
    CACHE_CREATE=$(echo "$USAGE" | jq -r '.cache_creation_input_tokens // 0')
    CACHE_READ=$(echo "$USAGE" | jq -r '.cache_read_input_tokens // 0')

    CURRENT=$((INPUT_TOKENS + OUTPUT_TOKENS + CACHE_CREATE + CACHE_READ))
    REMAINING=$((CONTEXT_SIZE - CURRENT))
    PERCENT=$((CURRENT * 100 / CONTEXT_SIZE))

    # Format remaining as K
    if [ $REMAINING -gt 1000 ]; then
        REMAINING_FMT="$((REMAINING / 1000))k"
    else
        REMAINING_FMT="$REMAINING"
    fi

    # Color based on usage
    if [ $PERCENT -lt 50 ]; then
        echo "Context: ${PERCENT}% | ${REMAINING_FMT} remaining"
    elif [ $PERCENT -lt 80 ]; then
        echo "Context: ${PERCENT}% | ${REMAINING_FMT} remaining ⚠️"
    else
        echo "Context: ${PERCENT}% | ${REMAINING_FMT} remaining 🔴"
    fi
else
    echo "Context: 0%"
fi

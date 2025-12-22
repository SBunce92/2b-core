# Claude Code wrapper function with vault integration
# Source this from your .zshrc: source ~/vault/_claude/core/scripts/cc-function.sh

cc() {
    local vault_path="${VAULT_PATH:-$HOME/vault}"
    local agents_file="$vault_path/_claude/core/agents.json"

    case "$1" in
        --update|-u)
            # Update 2b-core system files
            "$vault_path/_claude/core/scripts/2b-update" "${@:2}"
            ;;
        --update-dry)
            # Preview 2b-core updates
            "$vault_path/_claude/core/scripts/2b-update" --dry-run
            ;;
        --resume|-r)
            shift
            cd "$vault_path" || return 1
            if [[ -f "$agents_file" ]]; then
                claude --resume --dangerously-skip-permissions --agents "$(jq -c '.' "$agents_file")" "$@"
            else
                claude --resume --dangerously-skip-permissions "$@"
            fi
            ;;
        --continue|-c)
            shift
            cd "$vault_path" || return 1
            if [[ -f "$agents_file" ]]; then
                claude --continue --dangerously-skip-permissions --agents "$(jq -c '.' "$agents_file")" "$@"
            else
                claude --continue --dangerously-skip-permissions "$@"
            fi
            ;;
        --sync|-s)
            cd "$vault_path" || return 1
            git add -A && git commit -m "Sync: $(date +%Y-%m-%d)" && git push
            ;;
        --health|-h)
            "$vault_path/_claude/core/scripts/health.sh"
            ;;
        "")
            cd "$vault_path" || return 1
            if [[ -f "$agents_file" ]]; then
                claude --dangerously-skip-permissions --agents "$(jq -c '.' "$agents_file")"
            else
                claude --dangerously-skip-permissions
            fi
            ;;
        *)
            cd "$vault_path" || return 1
            if [[ -f "$agents_file" ]]; then
                claude --dangerously-skip-permissions --agents "$(jq -c '.' "$agents_file")" "$@"
            else
                claude --dangerously-skip-permissions "$@"
            fi
            ;;
    esac
}

# Aliases
alias ccr='cc --resume'
alias ccc='cc --continue'
alias ccu='cc --update'

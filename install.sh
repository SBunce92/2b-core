#!/bin/bash
# 2b-core vault installer
# Usage: curl -fsSL https://raw.githubusercontent.com/SBunce92/2b-core/main/install.sh | bash
#
# Options (via env vars):
#   VAULT_PATH=/custom/path  - Install location (default: ~/vault)
#   SKIP_SHELL=1             - Skip shell integration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VAULT_PATH="${VAULT_PATH:-$HOME/vault}"
REPO="https://github.com/SBunce92/2b-core.git"

echo ""
echo -e "${GREEN}2b-core vault installer${NC}"
echo "========================"
echo ""

# Check prerequisites
check_prereqs() {
    local missing=()
    command -v git >/dev/null || missing+=("git")
    command -v jq >/dev/null || missing+=("jq (brew install jq)")

    if ! command -v claude >/dev/null; then
        echo -e "${YELLOW}Note: Claude Code CLI not found. Install from: https://claude.com/claude-code${NC}"
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Missing prerequisites:${NC}"
        for m in "${missing[@]}"; do
            echo "  - $m"
        done
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Prerequisites OK"
}

# Check for existing vault
check_existing() {
    if [[ -d "$VAULT_PATH" ]]; then
        echo -e "${YELLOW}Vault already exists at $VAULT_PATH${NC}"
        read -p "Overwrite? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
        rm -rf "$VAULT_PATH"
    fi
}

# Create vault structure
create_vault() {
    echo "Creating vault at $VAULT_PATH..."

    # Clone 2b-core to temp
    local tmp="/tmp/2b-core-install-$$"
    git clone --depth 1 --quiet "$REPO" "$tmp"

    # Create structure
    mkdir -p "$VAULT_PATH"
    cd "$VAULT_PATH"
    mkdir -p _claude/core _claude/hooks _claude/local log projects/_template _export

    # Copy core files
    cp -r "$tmp/_claude/core/"* _claude/core/
    cp -r "$tmp/_claude/hooks/"* _claude/hooks/ 2>/dev/null || true
    cp "$tmp/projects/_template/"* projects/_template/ 2>/dev/null || true

    # Make scripts executable
    chmod +x _claude/core/scripts/* 2>/dev/null || true
    chmod +x _claude/hooks/* 2>/dev/null || true

    # Create settings with hooks enabled
    cat > _claude/settings.local.json << 'SETTINGS_EOF'
{
  "statusLine": {
    "type": "command",
    "command": "\"$CLAUDE_PROJECT_DIR\"/_claude/core/scripts/statusline.sh"
  },
  "permissions": {
    "allow": [
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git push:*)",
      "Bash(git log:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(mkdir:*)",
      "Bash(ls:*)"
    ]
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/_claude/hooks/session-start.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/_claude/hooks/user-prompt-submit.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/_claude/hooks/stop.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
SETTINGS_EOF

    # Create CLAUDE.md
    cp "$tmp/CLAUDE.md" ./CLAUDE.md

    # Create .gitignore
    cat > .gitignore << 'EOF'
_export/
.DS_Store
.obsidian/
EOF

    # Create empty documents.json
    cat > documents.json << 'EOF'
{
  "_meta": {
    "last_rebuilt": null,
    "total_docs": 0
  }
}
EOF

    # Create empty entities.json (new schema)
    cat > entities.json << 'EOF'
{
  "_meta": {
    "last_rebuilt": null,
    "total_entities": 0
  }
}
EOF

    # Create first daily log with setup document
    local today=$(date +%Y-%m-%d)
    local time=$(date +%H:%M)
    cat > "log/$today.md" << EOF
# $today

## $time | discussion | 2b-core

Vault initialized with 2b-core document system.

---
EOF

    # Track version
    (cd "$tmp" && git rev-parse --short HEAD) > "$VAULT_PATH/_claude/.2b-core-version"

    # Cleanup temp
    rm -rf "$tmp"

    # Initialize git
    git init --quiet
    git add -A
    git commit --quiet -m "Initial vault setup with 2b-core"

    echo -e "${GREEN}✓${NC} Vault created"
}

# Shell integration
setup_shell() {
    if [[ -n "$SKIP_SHELL" ]]; then
        return
    fi

    local shell_rc=""
    if [[ -f ~/.zshrc ]]; then
        shell_rc=~/.zshrc
    elif [[ -f ~/.bashrc ]]; then
        shell_rc=~/.bashrc
    fi

    if [[ -z "$shell_rc" ]]; then
        echo -e "${YELLOW}Could not detect shell config file${NC}"
        return
    fi

    # Check if already configured
    if grep -q "VAULT_PATH" "$shell_rc" 2>/dev/null; then
        echo -e "${YELLOW}Shell already configured (VAULT_PATH found in $shell_rc)${NC}"
        return
    fi

    echo ""
    echo "Shell integration:"
    echo ""
    echo "  export VAULT_PATH=\"$VAULT_PATH\""
    echo "  source \"\$VAULT_PATH/_claude/core/scripts/cc-function.sh\""
    echo ""
    read -p "Add to $shell_rc? [Y/n] " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cat >> "$shell_rc" << EOF

# 2b-core vault
export VAULT_PATH="$VAULT_PATH"
source "\$VAULT_PATH/_claude/core/scripts/cc-function.sh"
EOF
        echo -e "${GREEN}✓${NC} Added to $shell_rc"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo "Vault location: $VAULT_PATH"
    echo ""
    echo "Next steps:"
    echo "  1. source ~/.zshrc  (or restart terminal)"
    echo "  2. cc               (start Claude in vault)"
    echo ""
    echo "Commands:"
    echo "  cc            - Start Claude Code in vault"
    echo "  cc --update   - Update 2b-core system files"
    echo "  cc --resume   - Resume last session"
    echo "  cc --sync     - Git sync vault"
    echo ""
}

# Main
check_prereqs
check_existing
create_vault
setup_shell
print_summary

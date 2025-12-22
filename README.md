# 2b-core

AI-first second brain. Log-based capture with Claude Code.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/SBunce92/2b-core/main/install.sh | bash
```

Custom location:
```bash
VAULT_PATH=~/my-vault curl -fsSL https://raw.githubusercontent.com/SBunce92/2b-core/main/install.sh | bash
```

After install:
```bash
source ~/.zshrc
cc              # Start Claude in vault
```

## Philosophy

- **Log is truth**: All information flows through append-only weekly logs
- **Index is derived**: Entity refs point to log ranges, regenerable
- **Ranges not lines**: Refs use `file:start:end` for safe extraction
- **AI-maintained**: Capture agents extract insights, update index

## Structure

```
vault/
├── CLAUDE.md              # AI instructions for this vault
├── entities.json          # Entity index with range refs (core artifact)
├── _claude/
│   ├── core/              # System files (managed by cc --update)
│   │   ├── agents.json    # Agent definitions
│   │   └── scripts/       # Shell helpers + cc function
│   ├── local/             # Your customizations (never touched)
│   └── .2b-core-version   # Tracks installed version
├── log/
│   └── YYYY-WXX.md        # Weekly logs (append-only)
├── projects/              # Materialized views per project
└── _export/               # Shareable artifacts (gitignored)
```

## Commands

```bash
cc              # Start Claude Code in vault
cc --update     # Pull latest 2b-core system files
cc --resume     # Resume last session
cc --continue   # Continue last session
cc --sync       # Git add, commit, push
```

## Shell Helpers

After sourcing `cc-function.sh`:

```bash
vref "Project-Name"              # Get refs for entity
vextract "log/2025-W52.md:75:131" # Extract content from ref
vcontext "Project-Name"          # Get all context for entity
vgrep "pattern"                  # Search logs
ventities                        # List all entities
vquick "Quick thought to log"    # Fast capture
vstat                            # Vault status
```

## Agents

Three built-in agents in `_claude/core/agents.json`:

- **capture**: Extract insights → append to log → update entity index
- **context**: Lookup entity → extract log ranges → synthesize
- **entities**: Rebuild index from logs with proper ranges

## Updating

```bash
cc --update          # Apply updates
cc --update --dry-run # Preview changes first
```

Updates sync `_claude/core/*` from this repo. Your `_claude/local/*` is never touched.

## Manual Setup

If you prefer manual installation:

1. Clone this repo
2. Copy `_claude/core/` to your vault
3. Copy `CLAUDE.md` and `projects/_template/`
4. Create `_state/`, `log/`, `_export/` directories
5. Add to `.zshrc`:
   ```bash
   export VAULT_PATH="$HOME/vault"
   source "$VAULT_PATH/_claude/core/scripts/cc-function.sh"
   ```

## License

MIT

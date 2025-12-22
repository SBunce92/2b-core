# 2b-core

Core system files for a log-based second brain, optimized for AI-first workflows.

## Philosophy

- **Log is truth**: All information flows through append-only weekly logs
- **Index is derived**: Entity refs point to log ranges, regenerable
- **Ranges not lines**: Refs use `file:start:end` for safe extraction
- **AI-maintained**: Capture agents extract insights, update index

## Setup

1. Create vault directory with this structure:
```
vault/
├── CLAUDE.md          # Copy from this repo
├── _claude/
│   ├── agents.json    # Agent definitions
│   └── scripts/
│       └── vaultrc    # Shell helpers
├── _state/
│   └── entities.json  # Entity index (will be created)
├── log/
│   └── YYYY-WXX.md    # Weekly logs
├── projects/
│   └── _template/
│       └── CONTEXT.md # Project template
└── _export/           # Shareable artifacts (gitignored)
```

2. Add to `.gitignore`:
```
_export/
.DS_Store
.obsidian/
```

3. Source shell helpers:
```bash
source /path/to/vault/_claude/scripts/vaultrc
```

## Usage

### Capture
After conversations, the capture agent:
1. Extracts decisions, insights, code, action items
2. Appends to current week's log
3. Updates entity index with range refs

### Lookup
```bash
# Get all refs for an entity
vref "Strike-PnL"

# Extract content from a ref
vextract "log/2025-W52.md:75:131"

# Get full context for an entity
vcontext "Strike-PnL"
```

### Quick capture
```bash
vquick "Decided to use range-based refs for safer extraction"
```

## License

MIT

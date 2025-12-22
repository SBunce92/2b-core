# Second Brain

Log-based capture system. Everything flows through `log/`.

## Structure

```
log/           # Weekly logs (YYYY-WXX.md) - append-only event store
_state/        # Entity index (entities.json) - derived, tracked
_claude/
  core/        # System files from 2b-core (managed by /update-2b)
  local/       # Vault-specific customizations
  skills/      # Skill definitions
projects/      # Materialized views per project
_export/       # Shareable artifacts (gitignored)
```

## Ref Format

All entity refs use ranges: `log/YYYY-WXX.md:START:END`
- START = first line of content block
- END = last line of content block (inclusive)
- Blocks separated by `---` or `## ` headers

Extraction: `sed -n 'START,ENDp' file`

## Lookup

```
Entity index: _state/entities.json
Read index → get refs → extract log entries at those ranges
```

## Agents

Defined in `_claude/core/agents.json`:

- **capture**: Extract insights → append to log → update index with ranges
- **context**: Lookup entity → extract relevant log entries
- **entities**: Rebuild index from logs with proper ranges

## Auto-Capture

After significant exchanges, spawn capture agent:
```
Task(subagent_type="capture", prompt="Capture insights from this conversation about [topic]")
```

## Shell Helpers

Source `_claude/core/scripts/vaultrc` for:
- `vextract <ref>` - Extract content from a ref
- `vref <entity>` - Get refs for an entity
- `vcontext <entity>` - Get all context for an entity
- `vgrep <pattern>` - Search logs
- `ventities` - List all entities
- `vquick <thought>` - Quick log entry
- `vstat` - Vault status

## 2b-core Updates

Run `/update-2b` to pull latest system files from github.com/SBunce92/2b-core.
- `_claude/core/*` = safe to overwrite
- `_claude/local/*` = never touched
- Version tracked in `_claude/.2b-core-version`

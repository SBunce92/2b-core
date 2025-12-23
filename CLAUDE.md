# Second Brain

Document-based capture system. Everything flows through `log/`.

## Structure

```
log/              # Daily logs (YYYY-MM-DD.md) - append-only
documents.json    # Document index with metadata
entities.json     # Entity → document mappings
_claude/
  core/           # System files from 2b-core (managed)
  local/          # Vault-specific customizations
  hooks/          # Session hooks
projects/         # Materialized views per project
_export/          # Shareable artifacts (gitignored)
```

## Document Format

Each document has a structured header:

```markdown
## HH:MM | kind | Entity1 | Entity2

Content summary and key points.

---
```

**Kinds:** `decision`, `design`, `review`, `debug`, `discussion`, `standup`, `research`, `retro`

## Document IDs

Format: `YYYY-MM-DD/NNN` (date + sequence number)

Example: `2025-12-22/003` = third document on Dec 22, 2025

## Indexes

### documents.json
```json
{
  "2025-12-22/001": {
    "file": "log/2025-12-22.md",
    "start": 3,
    "end": 15,
    "time": "14:30",
    "kind": "design",
    "entities": ["Project-Alpha", "Jane Smith"],
    "summary": "API architecture discussion"
  }
}
```

### entities.json
```json
{
  "Project-Alpha": {
    "type": "project",
    "docs": ["2025-12-22/001", "2025-12-20/003"],
    "first_seen": "2025-12-15",
    "doc_count": 12
  }
}
```

## Agents

Defined in `_claude/core/agents.json`:

- **capture**: Extract insights → create document → update indexes
- **context**: Lookup entity → synthesize from documents
- **entities**: Rebuild indexes from logs

## Rich Entity Linking

Every document explicitly lists entities in header. Enables:
- **Discovery**: `grep "| Project-Alpha" log/*.md`
- **Relationships**: Entities in same doc are related
- **Queries**: "Who works on X?" = entities sharing documents

## Auto-Capture

After significant exchanges, spawn capture agent:
```
Task(subagent_type="capture", prompt="Capture insights about [topic]")
```

## Shell Helpers

Source `_claude/core/scripts/vaultrc` for:
- `vdoc <id>` - Show document by ID
- `ventity <name>` - Get entity info
- `vkind <kind>` - List documents by kind
- `vgrep <pattern>` - Search logs
- `vquick <thought>` - Quick log entry
- `vrebuild` - Rebuild indexes from logs

## 2b-core Updates

```bash
2b-update              # Apply updates
2b-update --dry-run    # Preview changes
```
- `_claude/core/*` = safe to overwrite
- `_claude/local/*` = never touched

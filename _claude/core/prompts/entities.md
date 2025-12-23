# Entities Agent

Rebuild entity and document indexes from logs.

## Document Architecture

- **Logs**: Daily files at `log/YYYY-MM-DD.md`
- **Document ID**: `YYYY-MM-DD/NNN` (date + sequence)
- **Indexes**: `documents.json` + `entities.json`

## Task

### 1. Scan All Logs

Read all files in `log/` directory (both old weekly and new daily formats).

### 2. Parse Documents

Each document starts with header: `## HH:MM | kind | Entity1 | Entity2`

**Parse each document:**
```
Header: ## 14:30 | design | Project-Alpha | Jane Smith
        ↓
time: "14:30"
kind: "design"
entities: ["Project-Alpha", "Jane Smith"]
```

**For old format** (`## YYYY-MM-DD HH:MM | Entity1 | Entity2`):
- Extract date from header
- Default kind to "discussion"
- Extract entities after timestamp

### 3. Build documents.json

Create entry for each document:

```json
{
  "2025-12-22/001": {
    "file": "log/2025-12-22.md",
    "start": 3,
    "end": 15,
    "time": "14:30",
    "kind": "design",
    "entities": ["Project-Alpha", "Jane Smith"],
    "summary": "<first line of content>"
  }
}
```

**Document ID assignment:**
- For daily logs: `YYYY-MM-DD/NNN` where NNN is sequence in that file
- For weekly logs: `YYYY-WXX/NNN` for backwards compatibility

### 4. Build entities.json

For each unique entity found:

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

**Type inference:**
- First Last format → `person`
- Contains "Team" → `org`
- Known tech names → `tool`
- Default → `project`

**Derive from documents:**
- `docs`: All doc IDs where entity appears
- `first_seen`: Earliest doc date
- `doc_count`: Length of docs array

### 5. Preserve Manual Attributes

If existing entities.json has manual attributes (role, org, aliases), preserve them:

```json
{
  "Jane Smith": {
    "type": "person",
    "docs": [...],           // Rebuilt
    "first_seen": "...",     // Rebuilt
    "doc_count": 12,         // Rebuilt
    "role": "engineer",      // Preserved
    "org": "Platform-Team",  // Preserved
    "aliases": ["Jane"]      // Preserved
  }
}
```

### 6. Write Indexes

1. Write `documents.json` (complete rebuild)
2. Write `entities.json` (merge rebuilt + preserved attributes)

### 7. Return Summary

Report:
- Total documents found
- Total entities found
- New entities discovered
- Any parsing errors

## Entity Recognition

**In headers:** Entities are explicitly listed after kind.

**In content:** Also scan document content for entity mentions not in header:
- First Last names
- Project-Style-Names
- @mentions
- Technology names

If found in content but not header, still add to document's entity list.

## Output Schema

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
  },
  "_meta": {
    "last_rebuilt": "2025-12-22T23:00:00Z",
    "total_docs": 150
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
  },
  "_meta": {
    "last_rebuilt": "2025-12-22T23:00:00Z",
    "total_entities": 45
  }
}
```

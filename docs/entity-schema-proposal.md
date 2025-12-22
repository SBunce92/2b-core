# Unified Entity Schema Proposal

## Problem

Current schema has:
1. Separate `projects` and `people` top-level keys
2. `team` arrays on projects duplicating person names
3. Relationships maintained manually (error-prone, stale)

## Proposed Schema

```json
{
  "entities": {
    "Strike-PnL": {
      "type": "project",
      "refs": ["log/2025-W52.md:75:131", ...],
      "status": "staging-ready"
    },
    "Felix Poirier": {
      "type": "person",
      "refs": ["log/2025-W52.md:75:131", ...],
      "role": "direct-report",
      "org": "TA-Team"
    }
  },
  "_meta": {
    "last_updated": "2025-12-22",
    "total_lines": 42764
  }
}
```

## Key Changes

### 1. Single `entities` object
All entities (projects, people, concepts, tools) live in one flat namespace.

### 2. Explicit `type` field
Each entity declares its type:
- `project` - work efforts
- `person` - people
- `concept` - ideas, patterns (future)
- `tool` - technologies (future)

### 3. Relationships are implicit via shared refs
If two entities share a ref, they're related:
```
Strike-PnL.refs    = ["log/2025-W52.md:75:131", ...]
Felix Poirier.refs = ["log/2025-W52.md:75:131", ...]
```
Both reference lines 75-131 = mentioned together = related.

No explicit `team` arrays needed. Query: "who works on Strike-PnL?" = find all person entities with overlapping refs.

### 4. Attributes by type
Projects have: `status`, `repo`, `summary`
People have: `role`, `org`, `location`, `title`

## Benefits

1. **No duplication** - team membership derived from refs
2. **Always accurate** - refs come from logs, single source of truth
3. **Extensible** - add new entity types without schema changes
4. **Simpler agents** - one loop over entities, not separate project/people handling
5. **Better queries** - "what is Felix working on?" = find entities with shared refs

## Migration

1. Flatten structure: move all projects and people into `entities`
2. Add `type` field to each
3. Remove `team` arrays from projects
4. Keep person attributes (`role`, `org`, etc.)

## Example Query: "Who works on Strike-PnL?"

```javascript
const strikePnL = entities["Strike-PnL"];
const relatedPeople = Object.entries(entities)
  .filter(([name, e]) =>
    e.type === "person" &&
    e.refs.some(ref => strikePnL.refs.includes(ref))
  )
  .map(([name]) => name);
```

## Future: Entity Types

```json
{
  "ClickHouse": {
    "type": "tool",
    "refs": [...],
    "category": "database"
  },
  "Range-based refs": {
    "type": "concept",
    "refs": [...],
    "summary": "Using file:start:end format for safe extraction"
  }
}
```

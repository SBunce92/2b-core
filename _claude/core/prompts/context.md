# Context Agent

Retrieve and synthesize context about an entity from the document index.

## Document Architecture

- **Logs**: Daily files at `log/YYYY-MM-DD.md`
- **Indexes**: `documents.json` (doc metadata) + `entities.json` (entity → docs)

## Task

### 1. Find Entity

Read `entities.json` and locate the requested entity.

**Handle variations:**
- Check exact match first
- Check aliases if defined
- Try case-insensitive match
- Try partial match (e.g., "Alpha" → "Project-Alpha")

### 2. Get Document List

From entity entry, get list of document IDs:
```json
{
  "Project-Alpha": {
    "docs": ["2025-12-22/001", "2025-12-20/003", "2025-12-18/002"]
  }
}
```

### 3. Load Document Metadata

For each doc ID, read from `documents.json`:
```json
{
  "2025-12-22/001": {
    "file": "log/2025-12-22.md",
    "start": 3,
    "end": 15,
    "kind": "design",
    "entities": ["Project-Alpha", "Jane Smith"],
    "summary": "API architecture discussion"
  }
}
```

### 4. Extract Content (if needed)

For detailed context, extract actual content:
```bash
sed -n '3,15p' log/2025-12-22.md
```
Or use Read tool with offset/limit.

### 5. Synthesize Context

**Organize by kind:**
```
## Project-Alpha Context

### Decisions (2)
- 2025-12-22: Chose REST over GraphQL
- 2025-12-20: Decided on JWT auth

### Design (3)
- 2025-12-22: API architecture planning
- 2025-12-19: Database schema design
- 2025-12-18: Auth flow design

### Reviews (1)
- 2025-12-21: PR #42 review

### Related Entities
- Jane Smith (5 shared docs)
- Platform-Team (3 shared docs)
```

### 6. Find Related Entities

Entities that appear in same documents:
```javascript
const projectDocs = new Set(entity.docs);
const related = Object.entries(entities)
  .filter(([name, e]) =>
    name !== entityName &&
    e.docs.some(d => projectDocs.has(d))
  )
  .map(([name, e]) => ({
    name,
    shared: e.docs.filter(d => projectDocs.has(d)).length
  }))
  .sort((a, b) => b.shared - a.shared);
```

### 7. Return Summary

Provide:
- Entity overview (type, first seen, doc count)
- Documents grouped by kind
- Key decisions/insights
- Related entities
- Recent activity

## Query Types

**"What is X?"** → Overview + all context
**"Recent activity on X"** → Last 5-10 docs chronologically
**"Decisions about X"** → Filter to kind=decision
**"Who works on X?"** → Related person entities
**"X and Y"** → Documents containing both entities

## Fallback: Grep Search

If entity not in index, fall back to grep:
```bash
grep -l "Entity-Name" log/*.md
```

Then parse those files for context.

## Output Format

```markdown
# Context: Project-Alpha

**Type:** project
**First seen:** 2025-12-15
**Documents:** 12

## Recent Activity
- 2025-12-22 | design | API architecture discussion
- 2025-12-21 | review | PR #42 feedback
- 2025-12-20 | decision | Authentication approach

## Key Decisions
- REST over GraphQL (2025-12-22)
- JWT for auth (2025-12-20)

## Related Entities
- Jane Smith (engineer) - 5 shared docs
- Platform-Team - 3 shared docs
- Auth-Service - 2 shared docs

## Full Document List
[Chronological list of all docs with summaries]
```

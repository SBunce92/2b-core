# Capture Agent

Extract insights from conversation, create structured documents, update indexes.

## Document Architecture

- **Logs**: Daily files at `log/YYYY-MM-DD.md`
- **Document ID**: `YYYY-MM-DD/NNN` (date + sequence number)
- **Indexes**: `documents.json` (doc metadata) + `entities.json` (entity → docs)

## Task

### 1. Classify Document Kind

Determine the nature of what's being captured:

| Kind | Use When |
|------|----------|
| `decision` | An explicit choice was made |
| `design` | Architecture, system design, planning |
| `review` | Code review, PR feedback |
| `debug` | Investigating issues, troubleshooting |
| `discussion` | General conversation, brainstorming |
| `standup` | Status updates, sync meetings |
| `research` | Exploring topics, learning |
| `retro` | Retrospective, lessons learned |

### 2. Extract Entities

Identify ALL entities mentioned. Be thorough.

**Recognition patterns:**
- **Projects**: Capitalized names, kebab-case (`Project-Alpha`, `API-Gateway`)
- **People**: First Last format (`Jane Smith`, `John Doe`)
- **Tools**: Technology names (`PostgreSQL`, `Kubernetes`, `React`)
- **Orgs**: Teams, companies (`Platform-Team`, `Acme-Corp`)

**Normalization:**
1. Read `entities.json` to check for existing entities
2. Match aliases if defined (e.g., "Jane" → "Jane Smith")
3. Use consistent capitalization and formatting
4. When uncertain, create new entity with inferred type

**Entity type inference:**
- Contains "Team" or is a department → `org`
- Is a technology/framework → `tool`
- Is First Last format → `person`
- Default → `project`

### 3. Create Log Entry

**Header format:**
```markdown
## HH:MM | kind | Entity1 | Entity2 | Entity3
```

**Full entry:**
```markdown
## 14:30 | design | Project-Alpha | Jane Smith

Concise summary of what was discussed/decided.

Key points:
- Point one
- Point two

---
```

**Rules:**
- Time in 24-hour format
- Kind from the table above
- All extracted entities in header (enables grep discovery)
- Content is concise but complete
- End with `---` separator

### 4. Write to Daily Log

1. Determine today's date
2. Check if `log/YYYY-MM-DD.md` exists
   - If not, create with header: `# YYYY-MM-DD`
3. Read current file to find:
   - Last document sequence number (for new doc ID)
   - Line count (for positioning)
4. Append entry to end of file
5. Note the START and END line numbers

### 5. Update documents.json

Add new document entry:

```json
{
  "YYYY-MM-DD/NNN": {
    "file": "log/YYYY-MM-DD.md",
    "start": <first line of entry>,
    "end": <last line of entry>,
    "time": "HH:MM",
    "kind": "<kind>",
    "entities": ["Entity1", "Entity2"],
    "summary": "<one-line summary>"
  }
}
```

**Document ID**: Use date + sequence. If today has docs 001, 002, next is 003.

### 6. Update entities.json

For EACH entity in the document:

1. If entity exists: add doc ID to its `docs` array
2. If entity is new: create entry with inferred type

```json
{
  "Entity-Name": {
    "type": "project|person|tool|org",
    "docs": ["YYYY-MM-DD/NNN", ...],
    "aliases": []  // Optional, for recognition
  }
}
```

**For people**, add role/org if mentioned:
```json
{
  "Jane Smith": {
    "type": "person",
    "docs": [...],
    "role": "engineer",
    "org": "Platform-Team"
  }
}
```

### 7. Return Summary

Brief confirmation of what was captured:
- Document ID created
- Entities linked
- File updated

## Rich Entity Linking

The goal is **maximum discoverability**. Every document should be findable via any entity it mentions.

**Good capture:**
```
## 14:30 | design | API-Gateway | Auth-Service | Jane Smith | Platform-Team

Discussed authentication flow between services...
```
→ This doc appears in 4 entity indexes, discoverable from any angle.

**Bad capture:**
```
## 14:30 | discussion | API-Gateway

Talked about auth stuff with Jane...
```
→ Missing entities, poor discoverability.

**When in doubt, include the entity.** False positives (extra entities) are better than false negatives (missing entities).

## Guidelines

- Be thorough with entity extraction - err on side of inclusion
- Summaries should be standalone (understandable without original context)
- Use consistent entity naming across documents
- Check existing entities.json before creating duplicates

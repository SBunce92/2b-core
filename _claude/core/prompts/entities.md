# Entities Agent

Scan logs and rebuild/update the entity index with ranges.

## Task

1. Read current entities.json (may not exist)
2. Scan all log/*.md files for entity mentions:
   - Projects: Capitalized/kebab-case names (Strike-PnL, Toolbox)
   - People: First Last format (Felix Poirier)
3. For each entity, record refs as RANGES:
   - Find the content block containing the mention
   - Record as `file:START:END` where:
     - START = first line of the block
     - END = last line of the block
   - Blocks are separated by `---` or `##` headers
4. Write updated entities.json
5. Return summary of entities found

## Critical

ALWAYS use range format (`file:start:end`), never single lines (`file:line`).

This enables safe extraction: `sed -n 'START,ENDp' file`

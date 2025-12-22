# Capture Agent

Extract insights from conversation, append to log, update entity index.

## Task

1. Analyze the conversation for capture-worthy content:
   - Decisions made
   - Technical insights or patterns
   - Code discussed or written
   - Action items or next steps
   - Information about projects or people

2. Extract entities mentioned:
   - Projects (capitalized names, technical systems)
   - People (First Last format)

3. Create a log entry:
   ```markdown
   ## YYYY-MM-DD HH:MM | Entity1 | Entity2

   Concise summary of key points.

   ---
   ```

4. Append to log file:
   - Read log/YYYY-WXX.md (current week)
   - Use Edit to append your entry
   - Note the START and END line numbers of your entry

5. Update entity index with RANGES:
   - Read entities.json
   - Add new refs for each entity mentioned
   - CRITICAL: Use range format: `log/YYYY-WXX.md:START:END`
   - START = first line of the entry
   - END = last line of the entry (inclusive)
   - Example: `log/2025-W52.md:42650:42675`
   - Use Edit to update the file

6. Return brief summary of what was captured

## Guidelines

Be selective - capture insights, not chatter.

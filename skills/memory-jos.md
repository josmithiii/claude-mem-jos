# memory-jos — File-Based Long-Term Memory

A protocol for persistent, hierarchical memory across Claude Code sessions.

## When to Use This Skill

- Explicitly via `/memory-jos`
- When learning something significant about the user's preferences, workflows, or project patterns
- Before ending a long productive session (to preserve insights)
- After compaction (automatic via hook — see Post-Compaction Recovery)
- When the user says "remember this" or "don't forget"

## Memory Locations

- **Global**: `~/.claude/memory-jos/` — cross-project knowledge
- **Per-project**: `<project-root>/memory-jos/` — project-specific knowledge
- Each location has a `MEMORY-JOS.md` index and optional `<topic>.md` files

## Write Protocol

When writing memory:

1. **Choose scope**: global (preferences, workflows) vs. per-project (architecture, conventions)
2. **Choose file**: update an existing topic file, or create a new one if no fit
3. **Format entries** as date-stamped bullets:
   ```
   - [2026-02-15] User prefers pytest over unittest
   ```
4. **Update the index** (`MEMORY-JOS.md`) if you create a new topic file — add it under `## Topics`
5. **Keep topic files under 100 lines** — split or consolidate if they grow beyond that
6. **Keep the index concise** — it's injected every session, so no verbose prose

### Creating a Per-Project Memory

If no `<project-root>/memory-jos/` exists yet:
1. Create the directory and `MEMORY-JOS.md` with a project header
2. Add relevant project facts as date-stamped bullets
3. Create topic files as needed

## Read Protocol

- The `MEMORY-JOS.md` indexes (global + project) are **automatically injected** at session start via hook
- To read a topic file, use `Read` tool on the path shown in the index
- After compaction, re-read any topic files relevant to the current task

## Post-Compaction Recovery

When the session-start hook detects `source=compact`, it appends a recovery note:

```
[POST-COMPACTION RECOVERY] Context was compacted. Re-read relevant
topic files from memory-jos/ to restore working context.
```

When you see this note:
1. Check what task is in progress from the conversation
2. Re-read the relevant topic files listed in the injected index
3. Continue working — do NOT announce "I recovered from compaction"

## Consolidation Protocol

When the user asks to consolidate or clean up memory:
1. Read all topic files in the target scope
2. Remove stale/outdated entries
3. Merge duplicate entries across files
4. Ensure every topic file is listed in the index
5. Remove empty topic files

## ClaudeNotes.md Integration

- If `ClaudeNotes.md` exists in a project, it contains the user's curated session highlights
- Cross-reference before writing project memory to avoid duplication
- Memory-jos captures *patterns and preferences*; ClaudeNotes captures *session narratives*

## Usage Examples

```
/memory-jos
# → Claude reads current memory state and offers to update

"Remember that this project uses FastAPI with async endpoints"
# → Claude writes to per-project memory

"What do you remember about my testing preferences?"
# → Claude reads global memory and reports

"Consolidate my global memory"
# → Claude prunes and merges global memory-jos files
```

## Instructions

When `/memory-jos` is invoked explicitly:

1. Read `~/.claude/memory-jos/MEMORY-JOS.md`
2. If in a project, read `<project-root>/memory-jos/MEMORY-JOS.md` (if it exists)
3. Summarize what's currently stored
4. Ask the user if they want to add, update, or consolidate anything

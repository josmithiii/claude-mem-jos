# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

**memory-jos** is a file-based long-term memory system for Claude Code. It uses SessionStart/PreCompact hooks and a skill protocol to inject persistent memory into Claude sessions across conversations.

## Architecture

The system has three parts that work together:

1. **Hooks** (`hooks-jos/`) — Shell scripts registered in `~/.claude/settings.json`
   - `session-start-jos.sh`: Reads `MEMORY-JOS.md` index files (global + per-project, capped at 150 lines each) and outputs `additionalContext` JSON. On `source=compact`, appends a recovery note. Self-heals by seeding the memory directory on first run.
   - `pre-compact-jos.sh`: Appends a timestamped line to `compaction-log.txt` (info-only, cannot block compaction).

2. **Skill** (`skills/memory-jos.md`) — Protocol document that instructs Claude when/how to read and write memory files. Defines write format (date-stamped bullets), scoping rules (global vs per-project), post-compaction recovery behavior, and consolidation protocol.

3. **Installer/Uninstaller** (`install.sh`, `uninstall.sh`) — Copies hooks and skill into `~/.claude/`, patches `settings.json` with `jq`, seeds the global memory directory. Both are idempotent. Uninstall preserves memory data.

## Memory Layout (installed state)

```
~/.claude/memory-jos/MEMORY-JOS.md    # Global index (always injected)
~/.claude/memory-jos/<topic>.md        # Topic files (read on demand)
<project>/memory-jos/MEMORY-JOS.md     # Per-project index (injected when in-project)
```

## Common Commands

```bash
# Install (idempotent)
bash install.sh

# Uninstall (preserves memory data)
bash uninstall.sh

# Test the session-start hook produces valid JSON
~/.claude/hooks-jos/session-start-jos.sh

# Test post-compaction mode
CLAUDE_HOOK_EVENT_SOURCE=compact ~/.claude/hooks-jos/session-start-jos.sh
```

## Key Design Constraints

- **"-jos" suffix on everything** — distinguishes from built-in or third-party tools
- **Never overwrite existing memory** — `install.sh` skips seeding if `MEMORY-JOS.md` already exists
- **150-line cap per index** — keeps injection payload bounded; topic files hold depth
- **`jq` required** — all JSON construction uses `jq --arg` for safe escaping
- **`set -euo pipefail`** in all scripts — fail fast
- All hooks must output valid JSON or nothing; invalid output breaks Claude Code sessions

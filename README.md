# memory-jos

File-based long-term memory for [Claude Code](https://claude.ai/code).

Claude Code's built-in auto memory (`MEMORY.md`) is limited to 200 lines and
tightly coupled to the compaction system. **memory-jos** provides:

- **Hook-based context injection** — memory is injected via SessionStart hook, no line limit concerns
- **Post-compaction recovery** — after context compaction, a recovery note triggers re-reading of relevant memory
- **Hierarchical memory** — master index + topic files, both global and per-project
- **Hackable** — plain Markdown files, bash + jq, zero other dependencies

## Quick Start

```bash
git clone <this-repo> ~/claude-mem-jos
cd ~/claude-mem-jos
bash install.sh
```

Then start a new Claude Code session. Your memory is injected automatically.

## How It Works

```
Session Start
  → session-start-jos.sh reads MEMORY-JOS.md (global + project)
  → Outputs additionalContext JSON → Claude sees memory in context
  → Claude uses skill protocol to read/write memory during session

Compaction
  → pre-compact-jos.sh logs the event
  → SessionStart fires again with source=compact
  → Recovery note injected → Claude re-reads relevant topic files
```

## Memory Layout

```
~/.claude/memory-jos/                # Global (cross-project)
├── MEMORY-JOS.md                    # Master index (always injected)
├── <topic>.md                       # Topic files (read on demand)
└── sessions/
    └── compaction-log.txt           # Audit trail

<project>/memory-jos/                # Per-project (optional)
├── MEMORY-JOS.md                    # Project index (injected when in-project)
└── <topic>.md                       # Project topic files
```

## Usage

**Explicit**: Type `/memory-jos` to review and manage memory.

**Implicit**: Tell Claude "remember that I prefer pytest" or "remember this project uses FastAPI" — it writes to the appropriate memory scope.

**Consolidate**: Ask Claude to "consolidate my global memory" to prune stale entries and merge duplicates.

## Installed Files

| File | Location |
|------|----------|
| Skill | `~/.claude/skills/memory-jos.md` |
| SessionStart hook | `~/.claude/hooks-jos/session-start-jos.sh` |
| PreCompact hook | `~/.claude/hooks-jos/pre-compact-jos.sh` |
| Global memory | `~/.claude/memory-jos/MEMORY-JOS.md` |
| Hook config | Added to `~/.claude/settings.json` |

## Uninstall

```bash
bash uninstall.sh
```

Removes hooks and skill. Memory data is preserved at `~/.claude/memory-jos/` —
delete it manually if you want a clean slate.

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- `jq` (for JSON output in hooks)
- bash

## Design Decisions

- **"-jos" suffix everywhere** — distinguishes from built-in or third-party tools
- **Seed on first run** — the SessionStart hook creates the memory directory and index if missing, so it's self-healing
- **Never overwrite memory** — `install.sh` skips seeding if `MEMORY-JOS.md` already exists
- **150-line cap per index** — keeps injection payload bounded; use topic files for depth
- **PreCompact is info-only** — Claude Code's PreCompact hook cannot block or inject context, so we just log

## License

MIT

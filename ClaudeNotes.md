2026-02-15 11:03 - CCO - ~/.claude/skills/

❯ What "skills" exist for LLMs pertaining to managing long-term memory based on writing one or more files each session in a series of sessions?
  I imagine something like the following functionality:
  * Set a "prompt alarm" for when the context-buffer reaches X %
    (right now the user can watch this, but the CLI/IDE should support it also)
  * Update memory/memory.md and any other relevant memory/ files in response to such an alarm.
    (Presumably memory should be hierarchical and pulled in dynamically based on memory.md and the current task.)
  * CLAUDE.md of course points to memory/memory.md on startup
  * This would be an alternative to the current automatic compaction algorithm. Or is it largely equivalent?
  * Let me know if you are doing something like this already,
    and if so, point me to your memory file(s) so we can think about how to improve the session-to-session memory system.

⏺ Great question. Let me first show you what's already in place for you, then address the broader landscape.

  What You Already Have

⏺ Searched for 2 patterns, read 3 files (ctrl+o to expand)

⏺ Now let me search for what exists in the community and in Claude Code's own design.

⏺ 2 agents finished (ctrl+o to expand)
   ├─ claude-code-guide (Research Claude Code memory system) · 5 tool uses · 15.8k tokens
   │  ⎿  Done
   └─ Task (Search for LLM memory skills) · 8 tool uses · 18.5k tokens
      ⎿  Done

⏺ What You Already Have (Built-in)

  Claude Code already has a memory system active for you right now:

  - Auto memory directory: ~/.claude/projects/-Users-jos--claude-skills/memory/ (currently empty)
  - MEMORY.md: The first 200 lines are injected into every session's system prompt automatically
  - Topic files: You can create memory/debugging.md, memory/patterns.md, etc. -- Claude reads these on-demand when relevant
  - Your ~/.claude/CLAUDE.md: Already loaded every session (your JOS preferences, fail-fast rules, etc.)

  So the hierarchy is: CLAUDE.md (always fully loaded) → memory/MEMORY.md (first 200 lines auto-loaded) → memory/*.md topic files (read on demand).

  Your Specific Questions

  Prompt alarm at X% context?

  Not yet available. There's no hook or setting for context-threshold triggers. You can check manually with /context. The only compaction-related
  hooks are:
  - PreCompact -- fires before compaction (matcher: manual or auto)
  - SessionStart with matcher "compact" -- fires after compaction

  Memory update on compaction?

  You can wire this up partially today using hooks:
  {
    "PreCompact": [{
      "matcher": "auto",
      "hooks": [{"type": "command", "command": "~/.claude/hooks/save-before-compact.sh"}]
    }],
    "SessionStart": [{
      "matcher": "compact",
      "hooks": [{"type": "command", "command": "echo 'Session resumed after compaction. Check memory/MEMORY.md for context.'" }]
    }]
  }

  The limitation: hooks run shell commands only -- they can't invoke Claude to reason about what to save. They can capture mechanical state (git
  status, recent files, etc.) but not semantic summarization.

  Auto memory vs compaction?

  Complementary, not alternatives. CLAUDE.md and MEMORY.md survive compaction intact. Conversation history gets summarized/compressed. Auto memory is
   your hedge against compaction losing important details.

  The Ecosystem (What Others Have Built)

  There's a thriving ecosystem of exactly what you're imagining. The most relevant:

  ┌───────────────────┬───────────────────────────┬───────────────────────────────────────────────────────────────────────────────────┐
  │      Project      │         Approach          │                                    Key Feature                                    │
  ├───────────────────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
  │ claude-mem        │ Claude Code plugin        │ 3-layer progressive disclosure, ~10x token efficiency, auto-captures tool outputs │
  ├───────────────────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
  │ super-claude-kit  │ Zero-dep .claude/ install │ Memory graph with semantic connections, 52% token reduction                       │
  ├───────────────────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
  │ claude-cognitive  │ Attention-based           │ HOT/WARM/COLD file injection based on relevance scores                            │
  ├───────────────────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
  │ memory-mcp        │ MCP server                │ Hooks fire after every response + before compaction + session end                 │
  ├───────────────────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
  │ Mem0 via mcp-mem0 │ MCP + mature framework    │ Best benchmarks (26% accuracy improvement over OpenAI Memory)                     │
  ├───────────────────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
  │ Letta/MemGPT      │ OS-like memory tiers      │ Virtual memory analogy: in-context vs out-of-context, git-based versioning        │
  └───────────────────┴───────────────────────────┴───────────────────────────────────────────────────────────────────────────────────┘

  The Gap You've Identified

  You're right that there's a missing piece: threshold-triggered semantic memory consolidation. The ideal system would:

  1. Monitor context fill % → trigger at threshold (not yet supported by Claude Code hooks)
  2. Have the LLM itself reason about what to save (not just a shell script)
  3. Write hierarchical memory files (MEMORY.md index → topic files)
  4. Pull in relevant topic files dynamically based on current task

  claude-mem and memory-mcp come closest to this. The fundamental limitation is that Claude Code hooks can only run shell commands, not invoke Claude
   to reason. The MCP server approach (like memory-mcp) partially works around this by giving Claude tools to read/write memory during the session
  itself, rather than trying to automate it from hooks.

  My recommendation for your workflow

  The simplest starting point that requires no new dependencies:

  1. I can populate your memory/MEMORY.md at the end of each session with key learnings
  2. Add PreCompact + SessionStart(compact) hooks to your settings to preserve/restore context
  3. If you want more, claude-mem or memory-mcp are the most practical add-ons

  Want me to set up the hooks and seed your MEMORY.md, or would you rather explore one of the external tools first?

❯ /add-dir /w/claude-mem
  ⎿  Added /w/claude-mem as a working directory for this session · /permissions to manage

❯ I added claude-mem for you to inspect.  I like the idea of writing our own so we can experiment with various ideas.  To make sure I recognize
  our system relative to standard or imported tools, please add "-JOS" or "-jos" to our files and hook names, e.g., MEMORY-JOS.md.

⏺ Let me explore claude-mem first to understand what's worth borrowing, then we'll design our own.

...

Read(
~/.claude/projects/-Users-jos-w-lectures420/memory/MEMORY.md
)

...

 Here is Claude's plan:
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
 Plan: memory-jos -- File-Based Long-Term Memory System

 Context

 JOS wants to experiment with session-to-session memory for Claude Code. Claude Code's built-in auto memory
 (~/.claude/projects/<project>/memory/MEMORY.md) loads only the first 200 lines and is tightly coupled to the compaction system. We want a custom
 system that:

 - Uses hooks for context injection (not limited to 200 lines)
 - Provides post-compaction recovery
 - Supports hierarchical memory (index → topic files)
 - Is hackable, file-based, zero dependencies beyond bash + jq
 - Uses "-JOS"/"-jos" suffix on all files and hooks to distinguish from built-in/imported tools

 Files to Create

 1. ~/.claude/skills/memory-jos.md -- Memory Management Skill

 The skill defines the protocol that instructs Claude how/when to read and write memory. Key sections:

 - When to invoke: explicitly via /memory-jos, or when learning something significant, or before ending a long session
 - Memory locations: global (~/.claude/memory-jos/) and per-project (<project>/memory-jos/)
 - Write protocol: date-stamped bullet entries, topic files under 100 lines, index stays concise
 - Post-compaction protocol: after compaction, re-read relevant topic files; don't announce recovery
 - Consolidation protocol: prune stale entries, merge duplicates when asked
 - ClaudeNotes.md integration: cross-reference to avoid duplication

 2. ~/.claude/hooks-jos/session-start-jos.sh -- Context Injection Hook

 Reads MEMORY-JOS.md (global + project) and outputs JSON for additionalContext injection.

 - Reads global ~/.claude/memory-jos/MEMORY-JOS.md (capped at 150 lines)
 - Reads project $CWD/memory-jos/MEMORY-JOS.md if it exists (capped at 150 lines)
 - If source=compact, appends a [POST-COMPACTION RECOVERY] note
 - On first run, creates ~/.claude/memory-jos/ and seeds the index file
 - Outputs: {"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "..."}}
 - Fails fast if jq not found

 3. ~/.claude/hooks-jos/pre-compact-jos.sh -- Compaction Logger

 Lightweight audit trail -- appends one line per compaction event to ~/.claude/memory-jos/sessions/compaction-log.txt. Cannot block compaction or
 inject context (PreCompact is info-only).

 4. ~/.claude/memory-jos/MEMORY-JOS.md -- Seed Global Memory

 Initial index file with an "About JOS" section and empty Topics section. Template for how topic entries should be listed.

 5. Update ~/.claude/settings.json -- Register Hooks

 Add two hook entries alongside the existing Notification hook:

 "SessionStart": [{
   "matcher": "startup|clear|compact",
   "hooks": [{"type": "command", "command": "~/.claude/hooks-jos/session-start-jos.sh", "timeout": 10}]
 }],
 "PreCompact": [{
   "matcher": "",
   "hooks": [{"type": "command", "command": "~/.claude/hooks-jos/pre-compact-jos.sh", "timeout": 5}]
 }]

 All existing settings (Notification hook, statusLine, enabledPlugins, alwaysThinkingEnabled) preserved.

 6. Update ~/.claude/skills/CLAUDE.md -- Register New Skill

 Add memory-jos.md to the Current Skills list.

 Memory File Hierarchy

 ~/.claude/memory-jos/                # Global (cross-project)
 ├── MEMORY-JOS.md                    # Master index (always injected)
 ├── <topic>.md                       # Topic files (read on demand)
 └── sessions/
     └── compaction-log.txt           # Audit trail

 <project>/memory-jos/                # Per-project (when created)
 ├── MEMORY-JOS.md                    # Project index (injected when in-project)
 └── <topic>.md                       # Project topic files

 Data Flow

 Session Start → session-start-jos.sh reads MEMORY-JOS.md files
   → outputs additionalContext JSON → Claude sees injected memory
   → Claude uses skill protocol to read/write memory during session
   → Pre-compaction: pre-compact-jos.sh logs the event
   → Post-compaction: SessionStart fires again (source=compact)
   → Recovery note injected → Claude re-reads relevant topic files

 Verification

 1. Create all files, chmod +x the hook scripts
 2. Start a new Claude Code session -- verify memory context appears (check with /context or look for the "Global Memory" heading in initial context)
 3. Ask Claude to "remember that I prefer pytest over unittest" -- verify it writes to a topic file and updates the index
 4. Run /compact -- verify compaction-log.txt gets an entry, and the post-compaction recovery note appears
 5. In a new session, verify the memory from step 3 persists
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

 Claude has written up a plan and is ready to execute. Would you like to proceed?

 ❯ 1. Yes, clear context and auto-accept edits (shift+tab)
   2. Yes, auto-accept edits
   3. Yes, manually approve edits
   4. Type here to tell Claude what to change

⏺ I'll implement the full memory-jos system. Let me start by reading the files I need to modify and creating the new ones.
   ...
   mkdir -p ~/.claude/hooks-jos ~/.claude/memory-jos/sessions
   Write(memory-jos.md)   
   ...

⏺ All files created. Let me verify everything by testing the hook and reviewing the final state.

⏺ Bash(~/.claude/hooks-jos/session-start-jos.sh)
  ...
⏺ Bash(~/.claude/hooks-jos/pre-compact-jos.sh && cat ~/.claude/memory-jos/sessions/compaction-log.txt)
  ...
⏺ Bash(CLAUDE_HOOK_EVENT_SOURCE=compact ~/.claude/hooks-jos/session-start-jos.sh)
  ...
⏺ Let me also verify the settings.json is valid JSON.
  ...
⏺ Everything works. Here's a summary of what was created:

  Files Created

  ┌──────────────────────────────────────────┬──────────────────────────────────────────────────────────┐
  │                   File                   │                         Purpose                          │
  ├──────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ ~/.claude/skills/memory-jos.md           │ Skill protocol -- when/how Claude reads and writes memory │
  ├──────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ ~/.claude/hooks-jos/session-start-jos.sh │ SessionStart hook -- injects MEMORY-JOS.md into context   │
  ├──────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ ~/.claude/hooks-jos/pre-compact-jos.sh   │ PreCompact hook -- logs compaction events                 │
  ├──────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ ~/.claude/memory-jos/MEMORY-JOS.md       │ Seed global memory index                                 │
  ├──────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ ~/.claude/memory-jos/sessions/           │ Directory for compaction log                             │
  └──────────────────────────────────────────┴──────────────────────────────────────────────────────────┘

  Files Modified

  ┌────────────────────────────┬──────────────────────────────────────────────────────┐
  │            File            │                        Change                        │
  ├────────────────────────────┼──────────────────────────────────────────────────────┤
  │ ~/.claude/settings.json    │ Added SessionStart and PreCompact hook registrations │
  ├────────────────────────────┼──────────────────────────────────────────────────────┤
  │ ~/.claude/skills/CLAUDE.md │ Added memory-jos to Current Skills list              │
  └────────────────────────────┴──────────────────────────────────────────────────────┘

  Verified

  - Session-start hook outputs valid JSON with additionalContext containing the memory index
  - Post-compaction recovery appends the [POST-COMPACTION RECOVERY] note when source=compact
  - Pre-compact hook appends timestamped entries to compaction-log.txt
  - settings.json is valid JSON with all existing settings preserved

  Next Steps (Verification)

  Start a new Claude Code session to confirm the memory context is injected. You should see the "Global Memory
  (memory-jos)" heading in the context. Then try /memory-jos to interact with the skill, or tell Claude to "remember"
  something to test the write protocol.
   

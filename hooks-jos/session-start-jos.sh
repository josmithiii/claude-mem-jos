#!/usr/bin/env bash
# session-start-jos.sh — Inject long-term memory into Claude Code sessions
# Registered as a SessionStart hook in ~/.claude/settings.json
set -euo pipefail

# Fail fast if jq not found
command -v jq >/dev/null 2>&1 || { echo "FATAL: jq not found" >&2; exit 1; }

GLOBAL_MEM_DIR="$HOME/.claude/memory-jos"
GLOBAL_INDEX="$GLOBAL_MEM_DIR/MEMORY-JOS.md"

# First run: seed directory and index
if [ ! -d "$GLOBAL_MEM_DIR" ]; then
    mkdir -p "$GLOBAL_MEM_DIR/sessions"
fi
if [ ! -f "$GLOBAL_INDEX" ]; then
    cat > "$GLOBAL_INDEX" << 'SEED'
# MEMORY-JOS — Global Memory Index

## About Me
<!-- Edit this section with facts about yourself that Claude should know -->

## Topics
<!-- Add topic files as: - [topic-name](topic-name.md) — brief description -->
SEED
fi

# Build context string
context=""

# --- Global memory ---
if [ -f "$GLOBAL_INDEX" ]; then
    global_content=$(head -150 "$GLOBAL_INDEX")
    context+="# Global Memory (memory-jos)
${global_content}
"
fi

# --- Per-project memory ---
# CWD is the project root when hook fires
PROJECT_INDEX="$(pwd)/memory-jos/MEMORY-JOS.md"
if [ -f "$PROJECT_INDEX" ]; then
    project_content=$(head -150 "$PROJECT_INDEX")
    context+="
# Project Memory (memory-jos)
${project_content}
"
fi

# --- Post-compaction recovery note ---
# Claude Code sets CLAUDE_HOOK_EVENT_SOURCE when the hook fires
source="${CLAUDE_HOOK_EVENT_SOURCE:-}"
if [ "$source" = "compact" ]; then
    context+="
[POST-COMPACTION RECOVERY] Context was compacted. Re-read relevant
topic files from memory-jos/ to restore working context. Do not announce recovery.
"
fi

# Output JSON for additionalContext injection
jq -n --arg ctx "$context" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'

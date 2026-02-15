#!/usr/bin/env bash
# uninstall.sh — Remove memory-jos from ~/.claude/
# Does NOT delete memory data (~/.claude/memory-jos/) — only hooks and skill
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"

echo "memory-jos uninstaller"
echo "======================"

# --- Remove skill ---
if [ -f "$CLAUDE_DIR/skills/memory-jos.md" ]; then
    rm "$CLAUDE_DIR/skills/memory-jos.md"
    echo "Removed skills/memory-jos.md"
fi

# --- Remove hooks ---
if [ -f "$CLAUDE_DIR/hooks-jos/session-start-jos.sh" ]; then
    rm "$CLAUDE_DIR/hooks-jos/session-start-jos.sh"
    echo "Removed hooks-jos/session-start-jos.sh"
fi
if [ -f "$CLAUDE_DIR/hooks-jos/pre-compact-jos.sh" ]; then
    rm "$CLAUDE_DIR/hooks-jos/pre-compact-jos.sh"
    echo "Removed hooks-jos/pre-compact-jos.sh"
fi
# Remove hooks-jos dir if empty
rmdir "$CLAUDE_DIR/hooks-jos" 2>/dev/null && echo "Removed empty hooks-jos/" || true

# --- Remove only memory-jos hook entries from settings.json ---
SETTINGS="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
    tmp=$(mktemp)
    # Filter out hook groups whose commands reference hooks-jos/, then remove empty arrays
    jq '
      .hooks.SessionStart = ([.hooks.SessionStart // [] | .[] |
        select((.hooks // []) | all(.command | contains("hooks-jos/") | not))]) |
      .hooks.PreCompact = ([.hooks.PreCompact // [] | .[] |
        select((.hooks // []) | all(.command | contains("hooks-jos/") | not))]) |
      if .hooks.SessionStart == [] then del(.hooks.SessionStart) else . end |
      if .hooks.PreCompact == [] then del(.hooks.PreCompact) else . end |
      if .hooks == {} then del(.hooks) else . end
    ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    echo "Removed memory-jos hook entries from settings.json"
fi

# --- Remove from skills/CLAUDE.md ---
SKILLS_MD="$CLAUDE_DIR/skills/CLAUDE.md"
if [ -f "$SKILLS_MD" ] && grep -q "memory-jos.md" "$SKILLS_MD"; then
    grep -v "memory-jos\.md" "$SKILLS_MD" > "$SKILLS_MD.tmp"
    mv "$SKILLS_MD.tmp" "$SKILLS_MD"
    echo "Removed memory-jos from skills/CLAUDE.md"
fi

echo ""
echo "Done. Hook scripts and skill removed."
echo "Memory data preserved at: ~/.claude/memory-jos/"
echo "To delete memory data too: rm -rf ~/.claude/memory-jos/"

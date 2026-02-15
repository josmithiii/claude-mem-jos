#!/usr/bin/env bash
# install.sh — Install memory-jos into ~/.claude/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "memory-jos installer"
echo "===================="

# --- Prerequisites ---
if ! command -v jq >/dev/null 2>&1; then
    echo "FATAL: jq is required but not found. Install it first." >&2
    exit 1
fi

if [ ! -d "$CLAUDE_DIR" ]; then
    echo "FATAL: $CLAUDE_DIR does not exist. Install Claude Code first." >&2
    exit 1
fi

# --- Copy skill ---
echo "Installing skill..."
mkdir -p "$CLAUDE_DIR/skills"
cp "$SCRIPT_DIR/skills/memory-jos.md" "$CLAUDE_DIR/skills/memory-jos.md"

# --- Copy hooks ---
echo "Installing hooks..."
mkdir -p "$CLAUDE_DIR/hooks-jos"
cp "$SCRIPT_DIR/hooks-jos/session-start-jos.sh" "$CLAUDE_DIR/hooks-jos/session-start-jos.sh"
cp "$SCRIPT_DIR/hooks-jos/pre-compact-jos.sh" "$CLAUDE_DIR/hooks-jos/pre-compact-jos.sh"
chmod +x "$CLAUDE_DIR/hooks-jos/session-start-jos.sh"
chmod +x "$CLAUDE_DIR/hooks-jos/pre-compact-jos.sh"

# --- Seed memory (never overwrite existing) ---
echo "Seeding memory directory..."
mkdir -p "$CLAUDE_DIR/memory-jos/sessions"
if [ ! -f "$CLAUDE_DIR/memory-jos/MEMORY-JOS.md" ]; then
    cp "$SCRIPT_DIR/seed/MEMORY-JOS.md" "$CLAUDE_DIR/memory-jos/MEMORY-JOS.md"
    echo "  Created MEMORY-JOS.md — edit ~/.claude/memory-jos/MEMORY-JOS.md to personalize"
else
    echo "  MEMORY-JOS.md already exists, skipping"
fi

# --- Patch settings.json ---
echo "Patching settings.json..."
SETTINGS="$CLAUDE_DIR/settings.json"

if [ ! -f "$SETTINGS" ]; then
    # Create minimal settings with just our hooks
    cat > "$SETTINGS" << 'EOF'
{
  "hooks": {}
}
EOF
fi

# Add SessionStart hook — append to existing array, skip if our hook already present
if jq -e '.hooks.SessionStart // [] | map(.hooks[]?.command) | map(select(contains("hooks-jos/"))) | length > 0' "$SETTINGS" >/dev/null 2>&1; then
    echo "  SessionStart hook already registered, skipping"
else
    tmp=$(mktemp)
    jq '.hooks.SessionStart = (.hooks.SessionStart // []) + [{
        "matcher": "startup|clear|compact",
        "hooks": [{
            "type": "command",
            "command": "~/.claude/hooks-jos/session-start-jos.sh",
            "timeout": 10
        }]
    }]' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    echo "  Added SessionStart hook"
fi

# Add PreCompact hook — append to existing array, skip if our hook already present
if jq -e '.hooks.PreCompact // [] | map(.hooks[]?.command) | map(select(contains("hooks-jos/"))) | length > 0' "$SETTINGS" >/dev/null 2>&1; then
    echo "  PreCompact hook already registered, skipping"
else
    tmp=$(mktemp)
    jq '.hooks.PreCompact = (.hooks.PreCompact // []) + [{
        "matcher": "",
        "hooks": [{
            "type": "command",
            "command": "~/.claude/hooks-jos/pre-compact-jos.sh",
            "timeout": 5
        }]
    }]' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    echo "  Added PreCompact hook"
fi

# --- Update skills/CLAUDE.md ---
SKILLS_MD="$CLAUDE_DIR/skills/CLAUDE.md"
if [ -f "$SKILLS_MD" ]; then
    if ! grep -q "memory-jos.md" "$SKILLS_MD"; then
        # Append memory-jos entry after the last skill bullet in Current Skills
        SKILL_LINE='- **memory-jos.md** — File-based long-term memory system. Hierarchical index + topic files, injected via SessionStart hook. Invoke with `/memory-jos`.'
        # Find the last "- **" line number and insert after it
        last_skill=$(grep -n '^- \*\*.*\*\*' "$SKILLS_MD" | tail -1 | cut -d: -f1)
        if [ -n "$last_skill" ]; then
            { head -"$last_skill" "$SKILLS_MD"; echo "$SKILL_LINE"; tail -n +"$((last_skill + 1))" "$SKILLS_MD"; } > "$SKILLS_MD.tmp"
            mv "$SKILLS_MD.tmp" "$SKILLS_MD"
        else
            # No existing skill lines — append to end
            echo "$SKILL_LINE" >> "$SKILLS_MD"
        fi
        echo "  Added memory-jos to skills/CLAUDE.md"
    else
        echo "  memory-jos already in skills/CLAUDE.md, skipping"
    fi
else
    echo "  No skills/CLAUDE.md found, skipping (skill file is still installed)"
fi

echo ""
echo "Done! Start a new Claude Code session to activate."
echo "Run /memory-jos or say 'remember this' to start building memory."

#!/usr/bin/env bash
# pre-compact-jos.sh — Log compaction events for audit trail
# Registered as a PreCompact hook in ~/.claude/settings.json
# PreCompact is info-only: cannot block compaction or inject context
set -euo pipefail

LOG_DIR="$HOME/.claude/memory-jos/sessions"
LOG_FILE="$LOG_DIR/compaction-log.txt"

mkdir -p "$LOG_DIR"

timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
cwd=$(pwd)

echo "${timestamp} compact cwd=${cwd}" >> "$LOG_FILE"

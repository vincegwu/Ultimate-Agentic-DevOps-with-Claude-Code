#!/bin/bash
# LOG hook — records every terraform apply to the deploy log

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$CMD" | grep -q "terraform apply"; then
  LOG_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME")/.claude"
  mkdir -p "$LOG_DIR"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] terraform apply executed" >> "$LOG_DIR/deploy.log"
fi

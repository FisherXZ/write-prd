#!/usr/bin/env bash
set -e

SKILL_URL="https://raw.githubusercontent.com/FisherXZ/write-prd/main/SKILL.md"
SKILL_NAME="write-prd"

install_skill() {
  local dir="$1"
  mkdir -p "$dir"
  curl -fsSL "$SKILL_URL" -o "$dir/SKILL.md"
  echo "  ✓ Installed to $dir"
}

echo "Installing write-prd skill..."

# Claude Code
install_skill "$HOME/.claude/skills/$SKILL_NAME"

# Project-level agents (run from project root)
if [ -d ".cursor" ] || [ "$1" = "--all" ]; then
  install_skill ".cursor/skills/$SKILL_NAME"
fi
if [ -d ".gemini" ] || [ "$1" = "--all" ]; then
  install_skill ".gemini/skills/$SKILL_NAME"
fi
if [ -d ".codex" ] || [ "$1" = "--all" ]; then
  install_skill ".codex/skills/$SKILL_NAME"
fi
if [ -d ".opencode" ] || [ "$1" = "--all" ]; then
  install_skill ".opencode/skills/$SKILL_NAME"
fi

echo ""
echo "Done. Use /write-prd in Claude Code to get started."

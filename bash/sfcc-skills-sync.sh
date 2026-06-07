#!/usr/bin/env bash
# ~/bin/sfcc-skills-sync
# Copy canonical skills and commands from vault → Claude Code runtime
set -euo pipefail

VAULT="${VAULT:-$HOME/work/SFCC-Vault}"
SRC_SKILLS="$VAULT/90-Meta/skills"
SRC_COMMANDS="$VAULT/90-Meta/commands"
DEST_SKILLS="$HOME/.claude/skills"
DEST_COMMANDS="$HOME/.claude/commands"

if [[ ! -d "$SRC_SKILLS" ]]; then
  echo "Vault skills folder not found: $SRC_SKILLS" >&2
  exit 1
fi

mkdir -p "$DEST_SKILLS" "$DEST_COMMANDS"

# Skills are folders (SKILL.md inside) — copy each subfolder
echo "Syncing skills..."
for dir in "$SRC_SKILLS"/*/; do
  [[ -d "$dir" ]] || continue
  name="$(basename "$dir")"
  rsync -a --delete "$dir" "$DEST_SKILLS/$name/"
  echo "  ✓ $name"
done

# Commands are individual .md files
echo "Syncing commands..."
rsync -a --include="*.md" --exclude="_*" "$SRC_COMMANDS/" "$DEST_COMMANDS/"
ls "$SRC_COMMANDS"/*.md 2>/dev/null | while read -r f; do
  [[ "$(basename "$f")" == _* ]] && continue
  echo "  ✓ $(basename "$f")"
done

echo "Done. Restart any active Claude Code session for changes to take effect."
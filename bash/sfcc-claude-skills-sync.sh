#!/usr/bin/env bash
# sfcc-skills-sync
# Copy canonical skills and commands from the SFCC Vault into Claude Code's
# runtime locations. The vault is the source of truth; runtime is downstream.
#
# Install:
#   mkdir -p ~/bin
#   cp this-file ~/bin/sfcc-skills-sync
#   chmod +x ~/bin/sfcc-skills-sync
#   # Ensure ~/bin is on your PATH (zsh: usually is; if not, add to ~/.zshrc)
#
# Usage:
#   sfcc-skills-sync          # sync, normal output
#   sfcc-skills-sync --dry    # show what would change without copying
#   sfcc-skills-sync --quiet  # only print errors
#
# Source of truth:
#   $VAULT/90-Meta/skills/<name>/SKILL.md
#   $VAULT/90-Meta/commands/<name>.md
#
# Runtime targets:
#   ~/.agents/skills/<name>/SKILL.md     (skills — Claude Code reads here)
#   ~/.claude/commands/<name>.md         (commands — Claude Code reads here)

set -euo pipefail

# --- Configuration ----------------------------------------------------------

VAULT="${VAULT:-$HOME/work/aiworkspace/vaults/SFCC-Vault}"
SRC_SKILLS="$VAULT/90-Meta/skills"
SRC_COMMANDS="$VAULT/90-Meta/commands"
DEST_SKILLS="$HOME/.agents/skills"
DEST_COMMANDS="$HOME/.claude/commands"

DRY_RUN=0
QUIET=0
for arg in "$@"; do
  case "$arg" in
    --dry|--dry-run) DRY_RUN=1 ;;
    --quiet|-q)      QUIET=1 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Use --help for usage." >&2
      exit 2
      ;;
  esac
done

log() { [[ $QUIET -eq 0 ]] && echo "$@"; }
err() { echo "$@" >&2; }

# --- Sanity checks ----------------------------------------------------------

if [[ -z "${VAULT:-}" ]]; then
  err "VAULT is not set. Export it or edit this script."
  exit 1
fi

if [[ ! -d "$VAULT" ]]; then
  err "Vault not found: $VAULT"
  err "Set \$VAULT or move the vault into place."
  exit 1
fi

if [[ ! -d "$SRC_SKILLS" && ! -d "$SRC_COMMANDS" ]]; then
  err "Neither skills nor commands folder exists in the vault:"
  err "  $SRC_SKILLS"
  err "  $SRC_COMMANDS"
  err "Create them, add content, then re-run."
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  err "rsync is required but not installed."
  exit 1
fi

# --- Sync skills ------------------------------------------------------------

sync_skills() {
  [[ ! -d "$SRC_SKILLS" ]] && { log "No skills folder in vault — skipping."; return; }

  mkdir -p "$DEST_SKILLS"
  local count=0
  log "Syncing skills:"

  for dir in "$SRC_SKILLS"/*/; do
    [[ -d "$dir" ]] || continue
    local name
    name="$(basename "$dir")"

    # Skip the README-style folder if anyone ever creates one
    [[ "$name" == _* ]] && continue

    # Sanity check: every skill folder must have a SKILL.md
    if [[ ! -f "$dir/SKILL.md" ]]; then
      err "  ⚠ Skipping $name — no SKILL.md inside"
      continue
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
      rsync -an --delete --exclude='.obsidian' --exclude='.git' --exclude='.DS_Store' \
        "$dir" "$DEST_SKILLS/$name/" | grep -E '^[<>cd*]' | head -5 \
        | sed "s|^|  $name: |" || true
      log "  $name (dry-run)"
    else
      rsync -a --delete --exclude='.obsidian' --exclude='.git' --exclude='.DS_Store' \
        "$dir" "$DEST_SKILLS/$name/"
      log "  ✓ $name"
    fi
    count=$((count + 1))
  done

  log "  → $count skill(s) processed"
}

# --- Sync commands ----------------------------------------------------------

sync_commands() {
  [[ ! -d "$SRC_COMMANDS" ]] && { log "No commands folder in vault — skipping."; return; }

  mkdir -p "$DEST_COMMANDS"
  local count=0
  log "Syncing commands:"

  for f in "$SRC_COMMANDS"/*.md; do
    [[ -f "$f" ]] || continue
    local name
    name="$(basename "$f")"

    # Skip README-style files
    [[ "$name" == _* ]] && continue

    if [[ $DRY_RUN -eq 1 ]]; then
      log "  $name (dry-run)"
    else
      rsync -a "$f" "$DEST_COMMANDS/$name"
      log "  ✓ $name"
    fi
    count=$((count + 1))
  done

  log "  → $count command(s) processed"
}

# --- Run --------------------------------------------------------------------

log "Vault: $VAULT"
log "Skills target:   $DEST_SKILLS"
log "Commands target: $DEST_COMMANDS"
[[ $DRY_RUN -eq 1 ]] && log "(DRY RUN — no files will be written)"
log ""

sync_skills
log ""
sync_commands
log ""
log "Done. Restart any active Claude Code session for changes to take effect."

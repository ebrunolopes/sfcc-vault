---
type: runbook
date: 2026-05-22
status: active
last-verified: 2026-05-22
estimated-time: 30 min
tags: [observability, runbook]
---

# Runbook — New machine setup (Claude Code + SFCC skills + vault)

When setting up a new dev machine (lost laptop, fresh install, second device, disaster recovery).

## Prerequisites

- macOS or Linux (Windows works via WSL but paths differ — adapt accordingly)
- Node.js 18+ installed
- Access to the synced SFCC Vault (iCloud / Dropbox / git / Obsidian Sync — whatever you use)

## Steps

### 1. Restore the vault

Whatever sync mechanism you use, get the vault back to its canonical location. The path is up to you, but be consistent — every script and `CLAUDE.md` references `$VAULT`.

```bash
# Expected layout after restore:
ls ~/work/SFCC-Vault/90-Meta/skills/
# Should list your skill folders (sfcc-pr-review/, sfcc-tsd/, etc.)
```

### 2. Set `$VAULT` permanently

```bash
echo '' >> ~/.zshrc
echo '# SFCC Vault location' >> ~/.zshrc
echo 'export VAULT="$HOME/work/SFCC-Vault"' >> ~/.zshrc
source ~/.zshrc

echo $VAULT
# → /Users/<you>/work/SFCC-Vault
```

Adjust the path if your vault lives somewhere else.

### 3. Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

### 4. Install the Salesforce B2C Developer Toolkit plugins

```bash
claude plugin marketplace add SalesforceCommerceCloud/b2c-developer-tooling
claude plugin install b2c
claude plugin install b2c-dx-mcp
# Optional, depending on whether you adopted the CLI/composable storefront:
# claude plugin install b2c-cli
# claude plugin install storefront-next
```

This installs ~35 first-party SFCC skills into `~/.agents/skills/` and creates corresponding symlinks in `~/.claude/skills/`. Verify:

```bash
ls ~/.agents/skills/ | grep b2c | head
```

### 5. Recreate the sync script

```bash
mkdir -p ~/bin
```

Then paste the script (see **Sync script source** at the bottom of this runbook) into `~/bin/sfcc-skills-sync` and make it executable:

```bash
chmod +x ~/bin/sfcc-skills-sync
```

Ensure `~/bin` is on your `PATH`. On modern zsh / oh-my-zsh / starship setups it usually is. Verify with:

```bash
which sfcc-skills-sync
# → /Users/<you>/bin/sfcc-skills-sync
```

If "not found," add this to `~/.zshrc`:

```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 6. Run the sync

```bash
sfcc-skills-sync --dry    # preview
sfcc-skills-sync          # actually copy
```

Expected: vault skills → `~/.agents/skills/`, vault commands → `~/.claude/commands/`.

### 7. Set up global gitignore for Claude Code config files

`CLAUDE.md` and `.claude/` are personal context, never to be committed to client repos.

```bash
git config --global core.excludesfile ~/.gitignore_global
cat >> ~/.gitignore_global << 'EOF'

# Claude Code — personal context, never commit
CLAUDE.md
CLAUDE.local.md
.claude/
.claude.json
EOF
```

### 8. Verify

Start a Claude Code session:

```bash
cd ~  # any directory
claude
```

In the session, type:

```
/help
```

Confirm your custom commands appear (e.g. `jira-paste`, `analyze-requirements`). Skills don't show in `/help` since they trigger implicitly — you can verify them by asking Claude to do something that should activate one. For example:

```
> Pretend I just pasted a small SFRA controller diff. Would you use the sfcc-pr-review skill?
```

If it says yes and references the skill, you're set.

### 9. Optional but recommended

- **Initialize git in `~/.claude/` and `~/.agents/`** to track future changes:
  ```bash
  git -C ~/.claude init && git -C ~/.claude add . && git -C ~/.claude commit -m "Initial"
  git -C ~/.agents init && git -C ~/.agents add . && git -C ~/.agents commit -m "Initial"
  ```
- **Drop a starter `CLAUDE.md` into each SFCC repo** you work in. Template lives at `90-Meta/templates/claude-md-template.md` if you've created one (TODO).
- **Restore your IDE preferences and dotfiles** via your usual mechanism (these are separate from the vault).

## Verification checklist

- [ ] `$VAULT` resolves to the right path in a fresh terminal
- [ ] `ls "$VAULT/90-Meta/skills/"` shows the skill folders
- [ ] `which claude` returns a path
- [ ] `claude plugin list` shows `b2c` and `b2c-dx-mcp`
- [ ] `sfcc-skills-sync` runs without errors
- [ ] `ls ~/.agents/skills/` shows both b2c plugin skills and your custom skills
- [ ] `ls ~/.claude/commands/` shows your custom commands
- [ ] `claude` → `/help` lists the custom commands
- [ ] Test smoke: `/jira-paste` opens the interactive prompt, `cancel` exits cleanly

## Sync script source

If `~/bin/sfcc-skills-sync` is lost, recreate it from this listing. **Do not edit the script in the vault and expect it to take effect on your machine — the canonical script lives in `~/bin/` and there's no auto-sync for it.** (Yes, the script that syncs other things doesn't sync itself. That's intentional — bootstrap problem.)

```bash
#!/usr/bin/env bash
# sfcc-skills-sync
# Copy canonical skills and commands from the SFCC Vault into Claude Code's
# runtime locations. The vault is the source of truth; runtime is downstream.
#
# Usage:
#   sfcc-skills-sync          # sync, normal output
#   sfcc-skills-sync --dry    # show what would change without copying
#   sfcc-skills-sync --quiet  # only print errors

set -euo pipefail

VAULT="${VAULT:-$HOME/work/SFCC-Vault}"
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
      exit 2
      ;;
  esac
done

log() { [[ $QUIET -eq 0 ]] && echo "$@"; }
err() { echo "$@" >&2; }

[[ -z "${VAULT:-}" ]] && { err "VAULT is not set."; exit 1; }
[[ ! -d "$VAULT" ]] && { err "Vault not found: $VAULT"; exit 1; }
[[ ! -d "$SRC_SKILLS" && ! -d "$SRC_COMMANDS" ]] && {
  err "Neither skills nor commands folder exists in the vault."
  exit 1
}
command -v rsync >/dev/null 2>&1 || { err "rsync is required."; exit 1; }

sync_skills() {
  [[ ! -d "$SRC_SKILLS" ]] && { log "No skills folder in vault — skipping."; return; }
  mkdir -p "$DEST_SKILLS"
  local count=0
  log "Syncing skills:"
  for dir in "$SRC_SKILLS"/*/; do
    [[ -d "$dir" ]] || continue
    local name; name="$(basename "$dir")"
    [[ "$name" == _* ]] && continue
    if [[ ! -f "$dir/SKILL.md" ]]; then
      err "  ⚠ Skipping $name — no SKILL.md inside"
      continue
    fi
    if [[ $DRY_RUN -eq 1 ]]; then
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

sync_commands() {
  [[ ! -d "$SRC_COMMANDS" ]] && { log "No commands folder in vault — skipping."; return; }
  mkdir -p "$DEST_COMMANDS"
  local count=0
  log "Syncing commands:"
  for f in "$SRC_COMMANDS"/*.md; do
    [[ -f "$f" ]] || continue
    local name; name="$(basename "$f")"
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
```

## Changelog

| Date | Change |
|---|---|
| 2026-05-22 | Created. Captures vault-canonical setup, b2c plugin install, sync script bootstrap. |

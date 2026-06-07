# SFCC AIWorkspace

Personal knowledge base and AI tooling for Salesforce B2C Commerce Cloud (SFRA) development.

---

## Repository Structure

```
aiworkspace/
├── bash/
│   ├── sfcc-claude-skills-sync.sh   ← full-featured skills sync (recommended)
│   └── 
└── vaults/                            ← Obsidian vault root
    ├── SFCC-Vault/                  ← notes, skills, commands, templates
    ├── Ollama/                      ← local AI tooling docs
    └── ai-reports/                  ← generated reports (git-ignored)
```

---

## Bash Scripts

### `sfcc-claude-skills-sync.sh` — Full-featured sync (recommended)

Copies skills and commands from the vault into Claude Code's runtime locations.
The vault is the **source of truth** — runtime locations are downstream.

**Source → Destination:**

| Source (vault) | Destination (runtime) |
|---|---|
| `vaults/SFCC-Vault/90-Meta/skills/<name>/SKILL.md` | `~/.agents/skills/<name>/SKILL.md` |
| `vaults/SFCC-Vault/90-Meta/commands/<name>.md` | `~/.claude/commands/<name>.md` |

**Install:**

```bash
mkdir -p ~/bin
cp bash/sfcc-claude-skills-sync.sh ~/bin/sfcc-claude-skills-sync
chmod +x ~/bin/sfcc-claude-skills-sync
```

Ensure `~/bin` is on your PATH — add to `~/.zshrc` if needed:

```bash
export PATH="$HOME/bin:$PATH"
```

**Usage:**

```bash
# Sync skills and commands to Claude Code runtime
sfcc-claude-skills-sync

# Preview what would change without copying anything
sfcc-claude-skills-sync --dry

# Only print errors (silent on success)
sfcc-claude-skills-sync --quiet
```

**Custom vault path** (if your vault is not at `~/work/aiworkspace/vaults/SFCC-Vault`):

```bash
VAULT=/path/to/your/vault sfcc-claude-skills-sync
```

> Restart any active Claude Code session after syncing for changes to take effect.

---

---|---|
| `vaults/SFCC-Vault/90-Meta/skills/<name>/` | `~/.claude/skills/<name>/` |
| `vaults/SFCC-Vault/90-Meta/commands/*.md` | `~/.claude/commands/` |

**Install:**

```bash
mkdir -p ~/bin
cp bash/sfcc-skills-sync.sh ~/bin/sfcc-skills-sync
chmod +x ~/bin/sfcc-skills-sync
```

**Usage:**

```bash
sfcc-skills-sync
```

---

## Vault Structure

Skills and commands live under `vaults/SFCC-Vault/90-Meta/`:

```
90-Meta/
├── skills/
│   ├── sfcc-skill-pr-review/
│   │   └── SKILL.md
│   ├── sfcc-skill-tsd/
│   │   └── SKILL.md
│   └── sfcc-skill-self-review/
│       └── SKILL.md
└── commands/
    └── *.md
```

**Rules:**
- Every skill must be a folder containing a `SKILL.md` file
- Folders and files prefixed with `_` are ignored by both sync scripts
- `ai-reports/` is git-ignored — generated content, not tracked

---

## Setup on a New Machine

```bash
# 1. Clone the repo
git clone git@github-personal:ebrunolopes/sfcc-vault.git aiworkspace
cd aiworkspace

# 2. Install the sync script
mkdir -p ~/bin
cp bash/sfcc-claude-skills-sync.sh ~/bin/sfcc-claude-skills-sync
chmod +x ~/bin/sfcc-claude-skills-sync

# 3. Open Obsidian and point it to: ~/work/aiworkspace/vaults
# 4. Install the Obsidian Git plugin and configure auto-sync

# 5. Run initial sync to Claude Code runtime
sfcc-claude-skills-sync
```

---

## Git Workflow

This repo uses Obsidian Git for automatic sync:
- Auto pull every 5 minutes
- Auto commit and push every 10 minutes
- Commit message format: `vault: auto sync {{date}}`

For manual sync:

```bash
cd ~/work/aiworkspace
git pull
git add .
git commit -m "vault: manual sync"
git push
```

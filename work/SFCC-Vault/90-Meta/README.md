---
type: meta
tags: [meta]
---

# Skills (canonical source)

This folder is the **canonical source** for Claude Code skills. Edit here.

## Layout

Each skill is a subfolder containing a `SKILL.md`:
markdown

```markdown
---
type: meta
tags: [meta]
---

# Skills (canonical source)

This folder is the **canonical source** for Claude Code skills. Edit here.

## Layout

Each skill is a subfolder containing a `SKILL.md`:
```


````

## How Claude Code reads them

Claude Code reads from `~/.claude/skills/`, not from the vault.
After editing here, run:

```bash
sfcc-skills-sync
```

This copies `90-Meta/skills/` → `~/.claude/skills/` and
`90-Meta/commands/` → `~/.claude/commands/`.

Restart any active Claude Code session for changes to apply.

## Disaster recovery

On a new machine:

1. Clone or sync the vault to `~/obsidian/SFCC-Vault/`
2. Copy `~/bin/sfcc-skills-sync` from your dotfiles (or recreate it from `60-Runbooks/new-machine-setup.md`)
3. Run `sfcc-skills-sync`
4. Done — all skills and commands are live in Claude Code
````
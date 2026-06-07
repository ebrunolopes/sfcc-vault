---
type: meta
tags: [meta]
status: active
---

# Skills (canonical source)

This folder is the **canonical source** for Claude Code skills used in the SFCC workflow. Edit them here. Sync to runtime with `sfcc-skills-sync`.

## Layout

Each skill is its own subfolder containing a `SKILL.md`:

```
90-Meta/skills/
├── _README.md                    ← this file
├── sfcc-pr-review/
│   └── SKILL.md
├── sfcc-tsd/
│   └── SKILL.md
└── sfcc-health-check/
    └── SKILL.md
```

The subfolder pattern (rather than flat `.md` files) is required because some skills may include supporting files (scripts, templates, fixtures) alongside `SKILL.md`.

## How Claude Code reads them

Claude Code reads skills from `~/.agents/skills/`, **not from the vault**. After editing a skill here, run:

```bash
sfcc-skills-sync
```

That copies `$VAULT/90-Meta/skills/` → `~/.agents/skills/`. Restart any active Claude Code session for changes to apply.

> Note: this is different from where the Salesforce B2C Developer Toolkit installs its plugins. Those are symlinked into `~/.claude/skills/` pointing at `~/.agents/skills/`. The runtime location is the same; only the access path differs.

## Editing workflow

1. Edit `SKILL.md` here in Obsidian (or any editor pointed at the vault)
2. Run `sfcc-skills-sync`
3. Restart Claude Code
4. Test the skill on a representative input
5. Commit the change in the vault's git history (if you've initialized one)

## Disaster recovery

If your machine is lost or you set up a new one:

1. Restore the vault (iCloud / Dropbox / git / Obsidian Sync — whatever you use)
2. Install Claude Code: `npm install -g @anthropic-ai/claude-code`
3. Recreate `~/bin/sfcc-skills-sync` from the runbook at `60-Runbooks/new-machine-setup.md` (the script is inlined there)
4. Run `sfcc-skills-sync`
5. Done — every skill is live in Claude Code

## Frontmatter expectations

Each `SKILL.md` should declare:

```yaml
---
name: <skill-name>
description: >
  Short description ending with trigger conditions. Claude Code uses
  this to decide when to activate the skill, so be specific about the
  user phrasings and code patterns that should fire it.
---
```

Beyond that, structure the skill however serves its purpose. There's no enforced template — they're prompts, not schemas.

## Inventory

```dataview
TABLE WITHOUT ID file.link AS Skill, file.mtime AS "Last edited"
FROM "90-Meta/skills"
WHERE file.name = "SKILL"
SORT file.mtime DESC
```

## Related

- [[../commands/_README|Commands folder]]
- [[../skill-output-conventions|Skill output conventions]]
- [[../../60-Runbooks/new-machine-setup|New machine setup runbook]]

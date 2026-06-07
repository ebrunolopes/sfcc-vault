---
type: meta
tags: [meta]
status: active
---
# Commands (canonical source)

This folder is the **canonical source** for Claude Code slash commands used in the SFCC workflow. Edit them here. Sync to runtime with `sfcc-skills-sync`.

## Layout

Each command is a single markdown file:

```
90-Meta/commands/
├── _README.md                    ← this file
├── jira-paste.md
├── analyze-requirements.md
└── ...
```

## How Claude Code reads them

Claude Code reads commands from `~/.claude/commands/`, **not from the vault**. After editing a command here, run:

```bash
sfcc-skills-sync
```

That copies `$VAULT/90-Meta/commands/*.md` → `~/.claude/commands/`. Restart any active Claude Code session for changes to apply.

## Skills vs commands — when to use which

| | Slash command | Skill |
|---|---|---|
| **Invocation** | Explicit: user types `/name` | Implicit: triggered by content of the user's message |
| **Use case** | Multi-turn workflows, structured collection | Domain expertise applied to whatever the user is doing |
| **Examples** | `/jira-paste` (collects context interactively) | `sfcc-pr-review` (fires whenever the user asks for code review) |
| **Location** | `90-Meta/commands/<name>.md` → `~/.claude/commands/` | `90-Meta/skills/<name>/SKILL.md` → `~/.agents/skills/` |

Rule of thumb: if the user has to opt in to a workflow with a specific phrase, it's a **command**. If you want the model to apply expertise automatically when a topic comes up, it's a **skill**.

## Frontmatter expectations

Each command file should declare at least:

```yaml
---
description: One-line summary shown in /help and the slash command picker
---
```

The body of the command is freeform — it's the prompt Claude Code follows when the command runs.

## Inventory

```dataview
TABLE WITHOUT ID file.link AS Command, file.mtime AS "Last edited"
FROM "90-Meta/commands"
WHERE file.name != "_README"
SORT file.mtime DESC
```

## Related

- [[../skills/_README|Skills folder]]
- [[../skill-output-conventions|Output conventions]]
- [[../../60-Runbooks/new-machine-setup|New machine setup runbook]]

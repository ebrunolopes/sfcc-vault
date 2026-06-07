---
type: meta
tags: [meta]
---

# SFCC Architecture Vault

Personal knowledge base for Salesforce B2C Commerce Cloud work. Designed to compose with three custom Claude Code skills (`sfcc-tsd`, `sfcc-pr-review`, `sfcc-health-check`) and optionally the Superpowers workflow plugin.

## Start here

1. **[[00-Index/Home]]** — dashboard
2. **[[90-Meta/tag-taxonomy]]** — tag rules (read before tagging anything)
3. **[[90-Meta/skill-output-conventions]]** — how the SFCC skills write into the vault

## Folder map

| Folder | What lives here |
|---|---|
| `00-Index/` | Dashboards, Dataview-powered views |
| `10-Clients/` | All client-specific work (TSDs, reviews, incidents, integrations) |
| `20-ADRs/` | Vault-wide architectural decisions |
| `30-Patterns/` | Reusable SFCC patterns, client-agnostic |
| `40-Anti-Patterns/` | What not to do, paired with the right way |
| `50-Snippets/` | Pure code skeletons, no narrative |
| `60-Runbooks/` | Operational step-by-step guides |
| `70-References/` | External docs in your own words |
| `80-Inbox/` | Unsorted dump, weekly triage |
| `90-Meta/` | Vault rules, taxonomy, changelog |

## Required Obsidian plugins

- **Dataview** — powers every dashboard query in `00-Index/`
- **Templates** (core) — for inserting `_template-*.md` files

## Optional but useful

- **Templater** — richer template variables
- **Tag Wrangler** — rename tags safely
- **Obsidian Git** — version control the vault

## Composing with Claude Code skills

`sfcc-tsd`, `sfcc-pr-review`, `sfcc-health-check` should be updated to write into this vault per `[[90-Meta/skill-output-conventions]]`. The conventions doc is the contract — update both sides together.

## Composing with Superpowers

- `/superpowers:brainstorm` → save the discovery output to `80-Inbox/` until it earns a home
- `/superpowers:write-plan` → save to `10-Clients/<client>/Plans/` using the plan template
- `/superpowers:execute-plan` → runs the work; reviews land in `10-Clients/<client>/Reviews/`

## Sync Obsidian with Claude Code
❯ ~/bash/sfcc-claude-skills-sync.sh
---
type: meta
tags: [meta]
status: active
---

# Skill Output Conventions

How `sfcc-tsd`, `sfcc-pr-review`, and `sfcc-health-check` write into this vault. Update each skill's `SKILL.md` to honor this contract.

---

## `sfcc-tsd` → TSDs

**Path:** `10-Clients/<client>/TSDs/TSD-YYYY-MM-DD-<kebab-slug>.md`

**Frontmatter (required):**
```yaml
---
type: tsd
client: <ClientName>
project: <project-slug>
date: <YYYY-MM-DD>
status: draft        # draft | active | superseded | archived
sfcc-version: <e.g. 24.6>
sfra-version: <e.g. 7.1>
authors: [<name>]
related-prs: []
related-adrs: []
tags: [<domain-area>, <concern>, tsd]
---
```

**Body:** use `10-Clients/_template-client/TSDs/_template-tsd.md` as the starting structure.

---

## `sfcc-pr-review` → Reviews

**Path:** `10-Clients/<client>/Reviews/PR-<number>-<kebab-slug>.md`

**Frontmatter (required):**
```yaml
---
type: review
client: <ClientName>
pr: <number>
repo: <org/repo>
date: <YYYY-MM-DD>
reviewer: <name>
status: open         # open | resolved | wontfix
severity: <max-severity-found>   # critical | high | medium | low | info
tags: [<domain-areas>, <concerns>, review]
---
```

**Tag `#recurring`** when the same finding has appeared in 2+ prior reviews — signals promotion to `40-Anti-Patterns/`.

---

## `sfcc-health-check` → Health reports

**Path:** symlink `~/sfcc-reports/<client>/` into `10-Clients/<client>/Health-Reports/`.

**Frontmatter (required) — the skill should write this into each daily report:**
```yaml
---
type: health-report
client: <ClientName>
environment: dev     # dev | staging | prod
date: <YYYY-MM-DD>
tags: [observability, health-report, <env>]
---
```

The skill already writes to `~/sfcc-reports/YYYY-MM-DD/`. Restructure that to `~/sfcc-reports/<client>/YYYY-MM-DD-<env>.md` so the symlink stays clean.

---

## Cross-references

Any note can `[[link]]` to any other. Conventions:

- TSDs link to their ADRs in frontmatter (`related-adrs:`) **and** inline in the body
- Reviews link to relevant patterns/anti-patterns inline
- ADRs back-link to TSDs that triggered them
- Incidents link to the responsible PR (if known) and to follow-up reviews

## When in doubt

Drop the note in `80-Inbox/` with whatever frontmatter you can manage. Weekly triage moves it to the right place.

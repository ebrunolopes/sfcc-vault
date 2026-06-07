---
type: index
tags: [meta]
---

# SFCC Vault — Home

Dashboard for the SFCC architecture knowledge base. Requires the **Dataview** plugin.

> [!info] First time here?
> Read `90-Meta/tag-taxonomy.md` before tagging anything. Read `90-Meta/skill-output-conventions.md` to see how `sfcc-tsd`, `sfcc-pr-review`, and `sfcc-health-check` write into this vault.

---

## Active projects

```dataview
TABLE client AS Client, project AS Project, status AS Status, date AS Started
FROM "10-Clients"
WHERE type = "tsd" AND status != "archived" AND status != "superseded"
SORT date DESC
LIMIT 15
```

## Recent TSDs

```dataview
TABLE client, project, status, date
FROM "10-Clients"
WHERE type = "tsd"
SORT date DESC
LIMIT 20
```

## Open security findings from PR reviews

```dataview
TABLE client, file.link AS Review, date
FROM "10-Clients"
WHERE type = "review" AND contains(tags, "security") AND status != "resolved"
SORT date DESC
```

## Performance findings (open)

```dataview
TABLE client, file.link AS Review, date
FROM "10-Clients"
WHERE type = "review" AND contains(tags, "perf") AND status != "resolved"
SORT date DESC
```

## Incidents in last 90 days

```dataview
TABLE client, summary, severity, date
FROM "10-Clients"
WHERE type = "incident" AND date >= date(today) - dur(90 days)
SORT date DESC
```

## ADRs by status

```dataview
TABLE status, date
FROM "20-ADRs"
WHERE type = "adr"
SORT file.name ASC
```

## Pattern library

```dataview
LIST
FROM "30-Patterns"
WHERE type = "pattern"
GROUP BY file.folder
```

## Anti-patterns to watch for

```dataview
LIST
FROM "40-Anti-Patterns"
WHERE type = "anti-pattern"
```

## Inbox (needs triage)

```dataview
LIST
FROM "80-Inbox"
SORT file.mtime DESC
```

---

## Quick links

- [[Active-Projects]]
- [[Patterns-Catalog]]
- [[../90-Meta/tag-taxonomy|Tag taxonomy]]
- [[../90-Meta/skill-output-conventions|Skill output conventions]]
- [[../90-Meta/vault-changelog|Vault changelog]]

---
type: index
tags: [meta]
---

# Patterns Catalog

Curated reusable SFCC patterns, grouped by domain area. Patterns are timeless — no client-specific code here.

## All patterns

```dataview
TABLE WITHOUT ID file.link AS Pattern, tags
FROM "30-Patterns"
WHERE type = "pattern"
SORT file.folder ASC, file.name ASC
GROUP BY file.folder
```

## Anti-patterns

```dataview
TABLE WITHOUT ID file.link AS "Don't", reason
FROM "40-Anti-Patterns"
WHERE type = "anti-pattern"
SORT file.name ASC
```

## Promotion candidates

Reviews that repeatedly flag the same issue → promote to pattern or anti-pattern.

```dataview
TABLE client, file.link AS Review, tags
FROM "10-Clients"
WHERE type = "review" AND contains(tags, "recurring")
SORT date DESC
```

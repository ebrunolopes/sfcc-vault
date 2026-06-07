---
type: meta
tags: [meta]
---

# Anti-Patterns

Approaches to avoid. Each entry pairs with a `30-Patterns/` entry showing the right way.

## When to add

A finding reaches anti-pattern status when:
- It has appeared in 3+ PR reviews (`#recurring` tag), OR
- It caused a production incident, OR
- It violates a non-negotiable standard (security, output encoding, accessibility)

## Index

```dataview
TABLE reason, file.link AS "Anti-pattern"
FROM "40-Anti-Patterns"
WHERE type = "anti-pattern"
SORT file.name ASC
```

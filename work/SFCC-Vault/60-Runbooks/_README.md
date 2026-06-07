---
type: meta
tags: [meta]
---

# Runbooks

Step-by-step operational guides. Written for when something is on fire and you don't want to think.

## What belongs here

- Investigation procedures (log triage, hot-path debugging)
- Recovery procedures (rollback, credential rotation)
- Recurring operational tasks (cartridge deployment checklists)

## What does NOT belong here

- Architectural reasoning → `30-Patterns/` or `20-ADRs/`
- Client-specific procedures → `10-Clients/<client>/` (or link from here)

## Maintenance

Each runbook has a `last-verified` date. If it's older than 90 days, re-verify before relying on it.

## Index

```dataview
TABLE status, last-verified, estimated-time
FROM "60-Runbooks"
WHERE type = "runbook"
SORT file.name ASC
```

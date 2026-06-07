---
type: meta
tags: [meta]
---

# ADRs

Architectural Decision Records, vault-wide (not per-client).

## Rules

- Numbers are **sequential and never reused**, even when superseded.
- Filename: `NNNN-kebab-title.md` (zero-padded to 4 digits).
- Status transitions: `proposed → accepted → superseded | deprecated`.
- Superseded ADRs stay in the folder. They're history, not garbage.
- An ADR is for **non-obvious** decisions. "We chose JSON over XML" is not an ADR. "We chose SCAPI hooks over a custom controller for cart mutations because…" is.

## When to write one

- A TSD makes a choice that future engineers will question.
- A pattern is promoted from `30-Patterns/` to a binding decision.
- A trade-off explicitly rejects a tempting alternative.

## Template

[[_template-adr]]

## Index

```dataview
TABLE status, date
FROM "20-ADRs"
WHERE type = "adr"
SORT file.name ASC
```

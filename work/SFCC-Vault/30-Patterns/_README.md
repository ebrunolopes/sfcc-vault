---
type: meta
tags: [meta]
---

# Patterns

Reusable SFCC patterns. Client-agnostic. Timeless (no dates in filenames).

## Subfolders

- `Controllers/` — append/prepend/replace, route extension
- `Services/` — LocalServiceRegistry, circuit breakers, OAuth
- `Models-Decorators/` — model composition
- `Jobs/` — chunk vs task-oriented, idempotency
- `SCAPI-OCAPI/` — hooks, custom endpoints, migration
- `ISML/` — caching, remote includes, encoding
- `Performance/` — N+1, caching strategies, profiling

## When to add a pattern

1. You've used the approach 2+ times across projects
2. You can write a reference implementation that compiles
3. You can articulate when NOT to use it

If any of those isn't true, the note belongs in `80-Inbox/` until it is.

## Promotion from reviews

When `sfcc-pr-review` flags the same correct approach 3+ times across reviews, that's a signal to lift it here.

## Index

[[../00-Index/Patterns-Catalog]]

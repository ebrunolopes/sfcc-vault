---
type: meta
tags: [meta]
status: active
---

# Tag Taxonomy

**Source of truth for tags. Refer to this before inventing a new tag.**

Every note gets **exactly one tag from each of the first three axes**. No more. If a note seems to need five tags from one axis, it's actually multiple notes.

A fourth axis (`#client/*`) is available but discouraged — folder structure already encodes client.

---

## Axis 1 — Domain area (what part of SFCC)

Pick one. This is "where in the platform does this live?"

| Tag | Use for |
|---|---|
| `#sfra/controller` | Controllers, append/prepend/replace, route handlers |
| `#sfra/model` | SFRA models (cart, product, account…) |
| `#sfra/decorator` | Model decorators |
| `#sfra/isml` | ISML templates, remote includes |
| `#scapi` | SCAPI hooks, custom SCAPI endpoints |
| `#ocapi` | OCAPI hooks, OCAPI client config |
| `#service` | LocalServiceRegistry, service profiles, OAuth, circuit breakers |
| `#job` | Job steps, chunk-oriented jobs, schedules |
| `#hook` | Generic hook discussions not tied to SCAPI/OCAPI |
| `#bm` | Business Manager extensions |
| `#custom-object` | Custom object definitions and access |
| `#system-object` | System object extensions, attribute definitions |
| `#cartridge-path` | Cartridge overlay, path ordering, multi-site config |

## Axis 2 — Concern (why it matters)

Pick one. This is the "lens" of the note.

| Tag | Use for |
|---|---|
| `#perf` | Performance, caching, N+1, query optimization |
| `#security` | OWASP, input validation, output encoding, CSRF, authn/authz |
| `#a11y` | WCAG 2.1 AA, keyboard nav, ARIA, semantic HTML |
| `#testing` | mocha/chai/sinon, integration tests, fixtures |
| `#observability` | Logging, custom logs, log levels, monitoring |
| `#deprecation` | Pipelines→controllers, OCAPI→SCAPI, removed APIs |
| `#integration` | Third-party systems (OMS, PIM, IdP, payment, etc.) |

## Axis 3 — Status / type (what kind of note)

Pick one. Mirrors the `type` frontmatter field.

| Tag | Use for |
|---|---|
| `#pattern` | Reusable approach that works |
| `#anti-pattern` | Approach to avoid, with reason |
| `#adr` | Architectural Decision Record |
| `#tsd` | Technical Specification Document |
| `#review` | PR review output |
| `#runbook` | Step-by-step operational guide |
| `#incident` | Production incident writeup |
| `#snippet` | Pure code snippet, no narrative |
| `#draft` | Work in progress, not ready for reference |

---

## Optional Axis 4 — Client (use sparingly)

Only when you specifically want cross-client search and folder structure won't help.

`#client/ClientA` `#client/ClientB` `#client/shared`

## Other allowed tags (orthogonal to the three axes)

- `#dev` `#staging` `#prod` — environment-specific health reports
- `#recurring` — review finding seen 3+ times across PRs (signals promotion to anti-pattern)
- `#blocked` `#urgent` — workflow state, use sparingly

## Anything else?

**Don't invent new tags ad hoc.** If you genuinely need one, add it here first with a definition. The discipline is what keeps the system useful at 500+ notes.

---

## Examples

A TSD for a new OAuth integration at ClientA:
```
tags: [service, integration, tsd]
```

A PR review flagging N+1 in a controller:
```
tags: [sfra/controller, perf, review, recurring]
```

An ADR choosing SCAPI over OCAPI for cart mutations:
```
tags: [scapi, integration, adr]
```

A runbook for investigating OCAPI 500 spikes:
```
tags: [ocapi, observability, runbook]
```

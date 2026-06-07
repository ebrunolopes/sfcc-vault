---
type: review
client: <ClientName>
pr: <number>
repo: <org/repo>
branch: 
date: <YYYY-MM-DD>
reviewer: 
status: open         # open | resolved | wontfix
severity: medium     # max-severity-found: critical | high | medium | low | info
related-tsds: []
related-patterns: []
tags: [<domain-areas>, <concerns>, review]
---

# PR-<number> — <title>

> Filename: `PR-<number>-<kebab-slug>.md`

## Summary

One paragraph: what the PR does, scope, risk level.

## Findings

> Order by severity. Use the table below for a scan-friendly summary, then expand each finding inline.

| # | Severity | Area | Finding | Status |
|---|---|---|---|---|
| 1 | critical | sfra/controller | … | open |
| 2 | high | perf | … | resolved |
| 3 | medium | a11y | … | open |

### Finding 1 — <short title>

**Severity:** critical
**Tags:** `#sfra/controller` `#security`
**File:** `cartridges/.../controllers/X.js:42`

**Issue.** What's wrong.

**Why it matters.** Concrete impact.

**Suggested fix.**
```js
// before

// after
```

**Reference.** [[../../30-Patterns/.../<pattern>]] or SFCC doc link.

---

### Finding 2 — …

(repeat)

---

## What was done well

> Genuine positives. Reinforces good patterns.

- 

## Recurring patterns flagged

> Tag `#recurring` if any finding has appeared in 2+ prior reviews. Cross-link to the prior reviews and consider promoting to `40-Anti-Patterns/`.

- [[../../../10-Clients/<other-client>/Reviews/PR-XXX-…]]

## Follow-ups

- [ ] 
- [ ] 

## Sign-off

- [ ] All critical findings resolved
- [ ] All high findings resolved or accepted with rationale
- [ ] Tests cover the change (unit + integration where applicable)
- [ ] No new uncached SystemObjectMgr queries in loops
- [ ] ISML output encoding not disabled

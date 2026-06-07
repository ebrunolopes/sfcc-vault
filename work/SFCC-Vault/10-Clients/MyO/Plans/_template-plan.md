---
type: plan
client: <ClientName>
project: <project-slug>
date: <YYYY-MM-DD>
status: draft        # draft | active | completed | abandoned
related-tsd: 
tags: [<domain-area>, plan]
---

# Plan — <feature/project title>

> Output of Superpowers `write-plan` or manual planning session. Lives alongside the TSD it implements.

## Linked TSD

[[../TSDs/TSD-…]]

## Tasks

> Each task: small, testable, sequenced. Mark dependencies explicitly.

### Task 1 — <short title>

- **Files touched:** 
- **Depends on:** —
- **Test plan:** unit tests for X, integration test for Y
- **Acceptance:**
  - [ ] criterion
  - [ ] criterion

### Task 2 — <short title>

- **Files touched:** 
- **Depends on:** Task 1
- **Test plan:** 
- **Acceptance:**
  - [ ] 

## Risks

- 

## Review checkpoints

- [ ] After Task <N>: functional review against TSD section <X>
- [ ] After Task <M>: quality review (security, perf, a11y)

## Done when

- [ ] All tasks complete
- [ ] All tests pass
- [ ] `sfcc-pr-review` run with no open critical/high findings
- [ ] TSD status updated to `active`

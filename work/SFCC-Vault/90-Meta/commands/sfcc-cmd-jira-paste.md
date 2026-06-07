---
description: Interactively collect Jira ticket context and enrich a TSD in the SFCC vault.
---

You are running `/sfcc-cmd-jira-paste`. Interactive Jira-context collection to enrich an existing TSD.

## Phase 1 — Establish target

Ask in **one message**:
1. Full path to the TSD to enrich (under `<VAULT>/10-Clients/<Client>/TSDs/`)
2. Today's date (YYYY-MM-DD) for `ticket-snapshot-date`
3. Jira base URL for this client (e.g. `https://baccarat.atlassian.net`)

Resolve `<VAULT>` via: `$VAULT` → `CLAUDE.md` `vault-path:` → ask.

Wait for response. If anything missing, ask only for what's missing.

## Phase 2 — Collect tickets in a loop

Tell the user:

> Paste Jira ticket #1 below. Use this structure (any missing fields are fine):
>
> ```
> ### <KEY> — <Title>
> Status:
> Reporter:
> Assignee:
> Type: Story | Bug | Task | Epic
>
> **Description:**
>
> **Acceptance criteria:**
> -
>
> **Relevant comments:**
> - [Author, YYYY-MM-DD]:
>
> **Linked tickets:**
> - Epic:
> - Blocks:
> - Blocked by:
> - Relates to:
> ```
>
> After each ticket, I'll ask if you have another. Type `start now` (or `done`, `go`, `enrich`) when ready.

Loop: accept → "Got <KEY>. Next, or `start now`?" → repeat.

**Sentinels** (case-insensitive, entire message): `start now`, `done`, `go`, `enrich`, `that's all`, `proceed`.
**Empty paste** → ask for content or sentinel.
**Missing `### <KEY>` header** → ask for a key.
**Zero tickets + sentinel** → abort.

## Phase 3 — Enrich the TSD

Read the target TSD. Update:

**Frontmatter:**
- Add ticket keys to `related-tickets` (preserve existing)
- Add/update `ticket-snapshot-date: <date>`

**§1 Context & purpose:**
- Enrich with business framing from primary ticket description — paraphrased
- Preserve existing technical context

**§2 Goals & non-goals:**
- Map AC to goal bullets
- Out-of-scope items → non-goals

**§3 Stakeholders:**
- Add reporter + assignee from primary ticket

**§9 or §10 Open questions:**
- Add unresolved questions from comments

**§11 Links:**
- Add ticket URLs: `[KEY](<base-url>/browse/KEY) — _last synced YYYY-MM-DD_`
- Group: Primary, Epic, Blocks/Blocked-by, Relates-to

**§4–8 (technical design): DO NOT MODIFY.**

**Contradictions:** If ticket content conflicts with technical design in §4–8, do NOT silently change. Output a `⚠️ Contradictions to review` section listing each conflict.

## Phase 4 — Confirm

```
✓ TSD enriched: <path>

Tickets added: <keys>
Sections enriched: <list>
Contradictions: <count or "none">

Open the file in Obsidian to review.
```

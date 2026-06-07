---
description: Self-review your current branch (your own code) — appends iteration on re-run. Modes: auto (default), full, interactive.
---

You are running `/sfcc-cmd-self-review`. Gather context, then invoke `sfcc-skill-self-review`.

For **your OWN code**. Use `/sfcc-cmd-pr-review` for someone else's PR.

## Parse mode

- `/sfcc-cmd-self-review` → `auto`
- `/sfcc-cmd-self-review full` (or `all`) → `full`
- `/sfcc-cmd-self-review interactive` (or `ask`) → `interactive`
- `base=<branch>` overrides base branch

## Phase 1 — Git state

1. `git rev-parse --show-toplevel` — abort if not a repo
2. `git branch --show-current` → `<branch>`
3. Base: user override > `develop` > `main` > `master`
4. If on base → abort: "Switch to your feature branch first."

## Phase 2 — Metadata

- **Identifier:** `feature/BCRTR-1558` → `BCRTR-1558`; `bugfix/1247-*` → `1247`; else ask
- **Client:** `CLAUDE.md` `client:` → prefix mapping (BCRTR→Baccarat, CWF→CWF, MYO→MyO) → ask
- **Repo:** `git remote get-url origin` → extract `org/repo`

## Phase 3 — Diff

```
git diff <base>...HEAD
```

Empty → abort: "No changes. Did you commit?" Large (>2000 lines / >40 files) → warn, await confirmation.

## Phase 4 — Invoke sfcc-skill-self-review

Pass: diff, metadata, mode. Skill handles section selection, iteration logic, vault write.

## Phase 5 — Confirm

```
✓ Self-review written: <path>
   (iteration <N>, mode: <mode>)

Next:
  1. Open in Obsidian
  2. Fix blockers, commit
  3. Run /sfcc-cmd-self-review again
  When READY → open the PR.
```

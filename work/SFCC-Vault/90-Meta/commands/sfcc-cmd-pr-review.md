---
description: Review someone else's open PR — overwrites on re-run, clean deliverable. Modes: auto (default), full, interactive.
---

You are running `/sfcc-cmd-pr-review`. Gather context for an **open PR by someone else**, then invoke `sfcc-skill-pr-review`.

For **OTHER PEOPLE'S code**. Use `/sfcc-cmd-self-review` for your own branch.

## Parse mode

- `/sfcc-cmd-pr-review` → `auto`
- `/sfcc-cmd-pr-review full` → `full`
- `/sfcc-cmd-pr-review interactive` → `interactive`
- `pr=<num>` specifies the PR. Combine: `/sfcc-cmd-pr-review pr=1247 full`

## Phase 1 — Find the PR

1. User specifies `pr=N` → use that
2. `gh pr view --json number,title,author,baseRefName,headRefName` → use if available
3. Ask: "Which PR? Number, URL, or check out the branch."

No open PR found → suggest: "Use `/sfcc-cmd-self-review` instead?"

Note the **author** (frontmatter needs it).

## Phase 2 — Metadata

- **PR number:** from Phase 1
- **Author:** from `gh pr view`
- **Base:** from `gh pr view` or `develop` / `main` / `master`
- **Client:** `CLAUDE.md` → prefix mapping → ask
- **Repo:** `gh repo view` or `git remote get-url origin`

## Phase 3 — Diff

```
gh pr diff <pr-number>
```

Or manually: `git fetch origin <base> <head>; git diff origin/<base>...origin/<head>`

Large diff → warn.

## Phase 4 — Existing file check

If `<VAULT>/.../Reviews/PR-<id>-*.md` exists → "I'll overwrite the existing review — current state is what matters."

## Phase 5 — Invoke sfcc-skill-pr-review

Pass: diff, metadata, mode. Skill handles section selection, constructive tone, vault write.

## Phase 6 — Confirm

```
✓ PR review written: <path>
   (mode: <mode>)

  🔴 <N> blockers   🟡 <N> warnings   🟢 <N> suggestions
  Verdict: APPROVE / REQUEST CHANGES / NEEDS DISCUSSION

Next: copy the Summary Report into the PR comment.
```

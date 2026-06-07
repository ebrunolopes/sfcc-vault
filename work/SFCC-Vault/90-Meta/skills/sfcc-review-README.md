# SFCC Code Review — User Guide

Two review commands for your SFCC/SFRA work:

| Command | Use when | Re-run behavior |
|---|---|---|
| `/self-review` | Reviewing **your own** branch (before PR, or while iterating on your own PR) | **Appends** an iteration section — tracks evolution |
| `/pr-review` | Reviewing **someone else's** open PR (you're the reviewer) | **Overwrites** — clean current-state artifact |

Both follow the same 9-category SFCC architect playbook (correctness, platform, security, payments, performance, accessibility, testing, deprecations, code quality). The differences are tone, output structure, and what happens on re-run.

---

## Quick start

### Reviewing my own branch

```
> /self-review
```

That's it. The command resolves everything (branch, base, client, identifier) from context and runs the review. Output:

- A punchy summary in chat (blockers first, fix list)
- A file at `$VAULT/10-Clients/<Client>/Reviews/SELF-<id>-<slug>.md` with the full details
- Verdict: **READY** / **FIX BLOCKERS** / **NEEDS RETHINK**

Fix the blockers, commit, run `/self-review` again. The file accumulates iterations — you see your work evolve.

When the verdict is READY, open the PR.

### Reviewing someone else's PR

```
> /pr-review pr=1247
```

Or, if you're already on the PR's branch with `gh` installed, just:

```
> /pr-review
```

Output:

- A clean, constructive structured review (copy-paste into the PR comment)
- A file at `$VAULT/10-Clients/<Client>/Reviews/PR-<num>-<slug>.md`
- Verdict: **APPROVE** / **REQUEST CHANGES** / **NEEDS DISCUSSION**

Re-running on the same PR overwrites the file. The PR's full review history is in GitHub.

---

## Review modes

Both commands support three modes. The default is smart enough that you usually don't need to think about modes.

### `auto` (default)

The skill runs **mandatory** sections always (correctness, platform, security, performance, deprecations, code quality), and **auto-detects** whether optional sections are relevant:

| § | Section | Auto-detection |
|---|---|---|
| 4 | Payments / Orders / OMS | Runs if diff touches payment/order code |
| 6 | Accessibility (WCAG 2.1 AA) | Runs if diff touches ISML or DOM-manipulating JS |
| 7 | Testing & Coverage | Runs if diff touches scripts or models |

When a section is skipped, the review explains why (one line).

```
> /self-review          # auto mode
> /pr-review pr=1247    # auto mode
```

### `full`

Runs every section regardless of what the diff contains. Use this when you want a comprehensive belt-and-braces audit.

```
> /self-review full
> /pr-review pr=1247 full
```

Synonym: `all`.

### `interactive`

Walks you through optional sections before running. Shows the auto-detection result for each and asks for overrides.

```
> /self-review interactive
> /pr-review pr=1247 interactive
```

You'll see:

```
This is a self-review on feature/BCRTR-1558.

Optional sections (auto-detected):
  §4 Payments/Orders/OMS Safety   →  skip (no payment code detected)
  §6 Accessibility (WCAG 2.1 AA)   →  run  (ISML changes detected)
  §7 Testing & Coverage            →  run  (scripts changed)

Mandatory sections (always run): §1 §2 §3 §5 §8 §9

Reply "ok" to accept these, or list overrides like "4 yes, 6 no":
```

Reply `ok` to take the auto-detection. Or override: `4 yes`, `skip 6`, `all yes`, etc.

Synonym: `ask`.

---

## When to use which mode

- **Default `auto`** — 90% of the time. The detection is reliable; skips are explained.
- **`full`** — Before a particularly risky merge (payment changes, auth changes, performance-sensitive paths). Belt-and-braces.
- **`interactive`** — Rarely needed. Useful if you disagree with the auto-detection and want explicit control without remembering exact override syntax.

---

## Iteration workflow (self-review)

```bash
# Code, code, code...
git add -A && git commit -m "Initial implementation"

claude
> /self-review
# Read the summary. If READY, open PR. If FIX BLOCKERS:

# Fix things, commit
git add -A && git commit -m "Address self-review blockers"

claude
> /self-review        # iteration 2 — shows what's left
```

Each iteration adds a section to the file:

```
## Iteration 1 — 2026-05-27
*Mode: auto. Sections ran: §1 §2 §3 §5 §7 §8 §9. Skipped: §4 §6.*

[3 blockers...]

## Iteration 2 — 2026-05-28
*Mode: auto. Sections ran: §1 §2 §3 §5 §7 §8 §9. Skipped: §4 §6.*

Previous blockers 1 and 2 resolved. New finding in...

[1 blocker remaining...]
```

Reading top-to-bottom shows how the work evolved.

---

## Reviewing a teammate's PR

```bash
# You've been assigned a review on PR #1247
claude
> /pr-review pr=1247
```

The skill:
- Fetches the PR diff (via `gh` if installed, otherwise asks you for it)
- Runs the review with constructive tone
- Writes the file to `$VAULT/10-Clients/<Client>/Reviews/PR-1247-<slug>.md`
- Outputs a hint to copy the Summary Report section into the PR comment

When the author pushes new commits and you re-review:

```
> /pr-review pr=1247   # overwrites with current state
```

The file is your **current-state review**. GitHub holds the history.

---

## Where the review files live

Inside the vault, organized by client:

```
$VAULT/10-Clients/
├── Baccarat/
│   └── Reviews/
│       ├── SELF-BCRTR-1558-checkout-fix.md     ← your own work
│       └── PR-1247-loyalty-decorator.md         ← someone else's PR
├── CWF/
└── MyO/
```

Filename convention:

- `SELF-<identifier>-<slug>.md` for self-reviews
- `PR-<number-or-key>-<slug>.md` for reviews of others' PRs

The prefix tells you at a glance who owns the code.

---

## Tips

- **`gh` CLI is your friend for `/pr-review`.** Install with `brew install gh && gh auth login`. Without it, you'll have to paste PR numbers and possibly diffs manually.
- **Drop a `CLAUDE.md` in each repo** with `client:` and `vault-path:` fields — the commands will resolve everything automatically with zero questions.
- **The first run always asks more questions** than subsequent runs in the same session. Once a session has resolved your vault path and client, it remembers.
- **If a section gets auto-skipped and you disagree**, use `/self-review interactive` (or `/pr-review pr=N interactive`) to override.

---

## What's NOT in this guide

For setup details, sync script, or disaster recovery, see:

- `$VAULT/90-Meta/skills/_README.md` — how the canonical-source pattern works
- `$VAULT/60-Runbooks/new-machine-setup.md` — new dev machine bootstrap
- `$VAULT/90-Meta/sfcc-vault-resume.md` — the living doc of the whole system

---
name: sfcc-skill-self-review
description: "Self-review for SFCC/SFRA branches the developer is working on themselves — typically before opening a PR, or while iterating on their own open PR. Triggers on: \"review my branch\", \"self-review\", \"pre-PR check\", \"is this ready\", \"check my code before I push\", or the /sfcc-cmd-self-review command. Iteration history is preserved. Do NOT use when reviewing someone else's PR — use sfcc-skill-pr-review for that."
---

# SFCC Self-Review

You are a **Senior SFCC Backend Architect** performing a self-review on the developer's own
feature branch. Catch issues before human review; track how the work evolved.

> **Authoritative sources.** When the `b2c` plugin is installed, defer to its skill files for
> current platform patterns over training-data conventions.

## Hard constraints

- Flag any unverified SFCC class, method, hook, site preference, or API with `⚠️ Unverified`.
- Do not guess or approximate — flag and move on.
- After completing the review, list all `⚠️ Unverified` items and ask:
  > "N items flagged as unverified. Want me to verify them with the b2c plugin? [yes/no]"
- If yes, verify each one and update the findings accordingly.

---

## Self-review specifics

- Lead with blockers — concrete fix per blocker
- Group findings by file
- Skip ceremonial praise
- Re-runs **append** an iteration section — the file tracks evolution
- Subjective findings → Suggestions, not Warnings

---

## Review modes

- **`auto`** (default) — mandatory sections always run; optional sections auto-skip when irrelevant
- **`full`** — all sections run
- **`interactive`** — walk user through optional sections before running

### Mandatory sections (always run)
1, 2, 3, 5, 8, 9

### Optional sections (auto-detect)

| § | Section | Run if diff touches… |
|---|---|---|
| 4 | Payments / Orders / OMS | `payment`, `Payment`, `OrderMgr`, `PaymentMgr`, files under `**/scripts/payment/` |
| 6 | Accessibility (WCAG 2.1 AA) | any `.isml` or client-side DOM-manipulating JS |
| 7 | Testing & Coverage | any `**/scripts/**/*.js` or `**/models/**/*.js` |

When skipping: `§N <name> — skipped (<reason>)` — one line.

### Interactive mode

Show auto-detection results, wait for `ok` or overrides (`4 yes`, `skip 6`).

---

## Review categories

### 1 — Correctness & business logic *(mandatory)*
All flows (guest/auth, locales, edge cases), silent regressions, conditionals, error paths.

### 2 — SFCC platform correctness *(mandatory)*
**Transactions.** Writes inside `Transaction.wrap()`. No missing, over-broad, or swallowed.
**API usage.** Correct `dw.*` APIs. No deprecated. `ServiceResult.isOk()` checked.
**Cartridge layering.** No cross-layer imports. `module.superModule` correct. Path order respected.
**Scripts.** Stateless. No `require()` cycles. Null-safe.

### 3 — Security & compliance *(mandatory)*
**CSRF.** POST routes use `csrfProtection`. **Access control.** Session-scoped, no horizontal escalation. **Logs.** No PII/tokens/secrets. **Input.** Validated via `server.forms.getForm()`. **ISML.** Default encoding on; flag `encoding="off"` without justification.

### 4 — Payments / orders / OMS *(optional)*
Idempotency, state transitions, `failOrder`/`cancelOrder`, payment instruments, no orphaned auths.

### 5 — Performance & caching *(mandatory)*
No N+1, no uncached `SystemObjectMgr` in loops, cache local vars, `setExpires`, remote includes, indexed queries, no sync HTTP in templates.

### 6 — Accessibility WCAG 2.1 AA *(optional)*
Semantic HTML, `<label>`, `aria-describedby`, keyboard nav, ARIA only when needed, `alt` text, color not sole signal, modal focus management.

### 7 — Testing & coverage *(optional)*
mocha/chai/sinon for scripts/models. Mirror paths. Stubs at boundaries. Edge cases. Missing tests flagged explicitly.

### 8 — Deprecations & modernization *(mandatory)*
Pipelines → controllers. OCAPI → SCAPI/Custom APIs. OAuth → SLAS. Hand-built CMS → Page Designer. Legacy jobs → Custom Job Steps. `HTTPClient` → `LocalServiceRegistry`. Defer to `b2c` plugin for current guidance.

### 9 — Code quality *(mandatory)*
SFRA conventions. No dead code. Clear naming. No magic strings. `Logger.getLogger('<category>', '<file>')`.

---

## Summary output

```
## Self-Review — <branch> → <base>  (iteration <N>)

**<count>** 🔴 blockers | **<count>** 🟡 warnings | **<count>** 🟢 suggestions

Sections: §1 §2 §3 §5 §8 §9 run | §4 §6 skipped (auto) | §7 ran

### 🔴 Must fix
1. [Category] file:line — description
   → Fix: concrete action

### 🟡 Worth fixing
1. …

### 🟢 Consider
- One-liner each.

### Verdict
- ✅ READY to open the PR
- 🔧 FIX BLOCKERS first, then re-run /sfcc-cmd-self-review
- ❌ NEEDS RETHINK

📄 Full review: <vault-path>
```

**Verdict rules:** 0 blockers → READY. Tactical blockers → FIX BLOCKERS. Design-level blockers → NEEDS RETHINK.

---

## Post-run verification

After the summary, if any `⚠️ Unverified` items were flagged:

```
---
⚠️ Unverified items (N):
  1. <class/method/hook that was flagged>
  2. …

Want me to verify these with the b2c plugin? [yes/no]
```

If yes, verify each item and update the review file with corrections. If no, leave the flags in place.

---

## Vault Output Convention

**Default: write to vault.** Skip only if user says "don't save."

### Vault root resolution
1. `$VAULT` env var → 2. repo `CLAUDE.md` `vault-path:` → 3. ask user

### Client resolution
1. `CLAUDE.md` `client:` → 2. branch prefix (BCRTR→Baccarat, CWF→CWF, MYO→MyO) → 3. ask

### Identifier
1. Branch ticket key (`feature/BCRTR-1558` → `BCRTR-1558`) → 2. branch numeric suffix → 3. ask

### Path
`<VAULT>/10-Clients/<Client>/Reviews/SELF-<identifier>-<kebab-slug>.md`

### Frontmatter
```yaml
---
type: self-review
client: <ClientName>
identifier: <ticket-key>
repo: <org/repo>
branch: <branch>
base: <base-branch>
date: <YYYY-MM-DD>
reviewer: Claude (sfcc-skill-self-review)
status: open
last-iteration: 1
last-iteration-date: <YYYY-MM-DD>
last-mode: auto
verdict: ready | fix-blockers | needs-rethink
sections-run: [1, 2, 3, 5, 7, 8, 9]
sections-skipped: [4, 6]
related-tsds: []
tags: [<domain>, <concern>, draft]
---
```

### Iteration behaviour
Exists → **append** `## Iteration N — <date>` with mode/sections subtitle. Update frontmatter `last-iteration`, `last-iteration-date`, `last-mode`, `verdict`. Never modify earlier iterations.

### When PR opens
User can: leave file, set `status: superseded-by-pr`, or delete.

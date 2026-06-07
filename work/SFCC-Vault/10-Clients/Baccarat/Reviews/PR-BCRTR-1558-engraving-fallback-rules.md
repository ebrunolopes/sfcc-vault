---
type: review
client: Baccarat
pr: BCRTR-1558
repo: OSFDigital/FR-BACCARAT-ITB-Rev-Sharing-SFRA-Migration-SFCC
branch: feature/BCRTR-1558
date: 2026-05-27
last-reviewed: 2026-05-28
reviewer: Bruno Lopes
pr-status: pre-merge
status: open
severity: high
iterations: 2
last-mode: auto
related-tsds: []
related-patterns: []
tags: [job, integration, review]
---

# PR-BCRTR-1558 — DWS Engraving Fallback Rules

## Summary

Refactors the engraving queue job to support row-level partial-success processing. Previously, a single failed engraving submission failed the entire order; now each product row is attempted independently, and only failed rows remain in `rowsToProcess` while succeeded rows move to `rowsProcessed`. The request-body defaults (brand, store, font, colour) are lifted out of the queue row and centralised in `engravingServiceHelpers.buildRequestBody`. An unrelated PayPal express-checkout fix (`setOrderType`) is also included. New CO metadata XML ships in `releases/2026_06_03`.

**Risk level:** Medium-high. The custom-object schema changes are breaking (old `payload` field replaced by `rowsToProcess`/`rowsProcessed`) and the queue is production-critical. Any in-flight CO at deploy time will have the old `payload` field and will fail the new `parseEntries` path silently.

---

## Findings

| #   | Severity | Area          | Finding                                                                     | Status |
| --- | -------- | ------------- | --------------------------------------------------------------------------- | ------ |
| 1   | high     | custom-object | `set-of-string` deduplicates — duplicate rows silently dropped              | open   |
| 2   | high     | job           | In-flight COs with old `payload` field will silently skip at deploy         | open   |
| 3   | medium   | job           | `order not found` path calls `removeSucceeded` without updating order       | open   |
| 4   | medium   | job           | `errorMessage` (text) can overflow on max-retry loops                       | open   |
| 5   | medium   | job           | `rowsProcessed` not initialised in `addToQueue` — `parseEntries(null)` path | open   |
| 6   | low      | style         | Mixed `const`/`let`/`var` across files in same PR                           | open   |
| 7   | low      | code          | Unrelated `setOrderType` change not in a separate commit                    | open   |
| 8   | info     | meta          | Missing newline at EOF in XML                                               | open   |

---

### Finding 1 — `set-of-string` deduplicates rows silently

**Severity:** high
**Tags:** `#custom-object` `#integration`
**File:** `cartridges/int_custom_services/cartridge/scripts/helpers/engravingQueueHelpers.js` · `releases/2026_06_03/meta/custom-objecttype-definitions.xml`

**Issue.** SFCC `set-of-string` attributes deduplicate by value. If an order has two line items with identical `productId` + `text` (e.g., two mugs both engraved "Merci"), `serializeEntries` will produce two identical JSON strings. When SFCC persists the set, one entry is silently discarded. The second engraving is never submitted and never retried.

**Why it matters.** Data loss — one engraving per duplicate pair is silently dropped with no error, no log, no retry. The customer receives an un-engraved product.

**Suggested fix.** Add a disambiguating field to each serialised entry before storing:
```js
// in serializeEntries, add a monotonic index before JSON.stringify
entries.push(JSON.stringify(Object.assign({ _idx: i }, arr[i])));
```
Or change the CO attribute to `type: text` (stores a single JSON blob) and do your own array serialisation:
```xml
<attribute-definition attribute-id="rowsToProcess">
    <type>text</type>   <!-- was set-of-string -->
```
The text approach is simpler and removes the deduplication risk entirely. It also preserves insertion order.

---

### Finding 2 — Deploy-time migration gap for in-flight COs

**Severity:** high
**Tags:** `#job` `#integration`
**File:** `cartridges/int_custom_jobs/cartridge/scripts/jobs/orders/processEngravingQueue.js:~140`

**Issue.** COs created before this deploy have `co.custom.payload` (a single JSON string). The new code reads `co.custom.rowsToProcess` (set-of-string). `parseEntries(null)` returns `[]`, so the job hits the early-continue guard (`rowsToProcess.length === 0`) and logs a warning rather than processing the engraving.

**Why it matters.** Any order queued at the moment of deploy will never be engraved and will never surface as a failure — it just gets skipped forever until `retention-days: 7` auto-deletes it.

**Suggested fix.** Add a migration shim in the processing loop, before calling `parseEntries`:
```js
// Migration shim — handle COs created before rowsToProcess was introduced
if ((!co.custom.rowsToProcess || !co.custom.rowsToProcess.length) && co.custom.payload) {
    var legacyPayloads = JSON.parse(co.custom.payload);
    rowsToProcess = legacyPayloads; // already parsed objects
} else {
    rowsToProcess = engravingQueue.parseEntries(co.custom.rowsToProcess);
}
```
Alternatively, schedule the job during a low-traffic window and accept the gap — but document this explicitly in the release notes.

---

### Finding 3 — Order-not-found path removes CO without updating order

**Severity:** medium
**Tags:** `#job` `#integration`
**File:** `cartridges/int_custom_jobs/cartridge/scripts/jobs/orders/processEngravingQueue.js:~240`

**Issue.** When all rows succeed but `OrderMgr.getOrder(orderNo)` returns null, the code calls `engravingQueue.removeSucceeded(co)` and increments `skipped`. This removes the CO permanently without writing any engraving status to the order.

**Why it matters.** If a CS agent cancelled and purged the order between queue creation and job execution, the engraving payload is discarded silently. This is probably acceptable business logic — but it should be `Logger.warn` (already done — good) **and** the CO should not be deleted; it should be marked `FAILED_MAX_RETRIES` so it's visible in BM for investigation.

**Suggested fix.**
```js
if (!order) {
    Logger.warn("processEngravingQueue - Order {0} not found, cannot update.", orderNo);
    engravingQueue.recordFailure(co, "Order not found at update time");
    failed++;
} else { ... }
```

---

### Finding 4 — `errorMessage` text attribute may overflow on max-retry loops

**Severity:** medium
**Tags:** `#job` `#observability`
**File:** `cartridges/int_custom_services/cartridge/scripts/helpers/engravingQueueHelpers.js:recordFailure`

**Issue.** `recordFailure` now appends a timestamped line to `errorMessage` on every call. With `MAX_RETRIES = 5` and multiple failed rows per order, the message grows as:
```
[2026-05-27T...] PRODUCT: 123 | MESSAGE: ...
[2026-05-27T...] PRODUCT: 456 | MESSAGE: ...
[2026-05-27T...] PRODUCT: 123 | MESSAGE: ...  (retry 2)
...
```
SFCC `text` attributes hold up to 32KB. A pathological failure loop (e.g., a service that always returns 429 with a long message body) can overflow this.

**Suggested fix.** Cap to the last N entries or limit `rowErrors.join("\n")` to a fixed character budget:
```js
var newEntry = "[" + new Date().toISOString() + "] " + (errorMessage || "").substring(0, 500);
var combined = existing ? existing + "\n" + newEntry : newEntry;
co.custom.errorMessage = combined.substring(combined.length - 10000); // keep last ~10KB
```

---

### Finding 5 — `rowsProcessed` not initialised in `addToQueue`

**Severity:** medium
**Tags:** `#job` `#custom-object`
**File:** `cartridges/int_custom_services/cartridge/scripts/helpers/engravingQueueHelpers.js:addToQueue`

**Issue.** `addToQueue` sets `rowsToProcess` but never initialises `rowsProcessed`. On the first partial-success run, `parseEntries(co.custom.rowsProcessed)` is called on an absent attribute. SFCC returns `null` for an unset `set-of-string`, and `parseEntries` guards `if (!rawEntry || !rawEntry.length) return []` — so this is safe today. But it is fragile: if `parseEntries` is ever changed or a different code path is added, the missing initialisation will cause a NPE.

**Suggested fix.** Explicitly initialise in `addToQueue` for clarity:
```js
co.custom.rowsToProcess  = rowsToProcess;
co.custom.rowsProcessed  = [];   // explicit empty set
```

---

### Finding 6 — Mixed `const`/`let`/`var` in the same PR

**Severity:** low
**Tags:** `#job` `#integration`
**Files:** `processEngravingQueue.js` (all `var`), `engravingServiceHelpers.js` (`const ENGRAVING_REQUEST_DEFAULTS`), `engravingQueueHelpers.js` (`const OBJECT_TYPE`, `let` in `addToQueue`)

**Issue.** The job file was explicitly converted from `let` to `var`, presumably to avoid Rhino compatibility issues. But `engravingServiceHelpers.js` introduces `const`, and `engravingQueueHelpers.js` still uses `let` inside `addToQueue`.

**Suggested fix.** Decide on a convention and apply it consistently within this PR. Given SFCC 24.6 supports `const`/`let` in Rhino, the safer choice is to standardise on `const`/`let` rather than regressing to `var`. If `var` was chosen for a specific reason, document it and apply it everywhere.

---

### Finding 7 — Unrelated `setOrderType` change mixed into engraving branch

**Severity:** low
**Tags:** `#sfra/controller` `#integration`
**File:** `cartridges/app_baccarat/cartridge/adyen/scripts/expressPayments/paypal/makeExpressPaymentDetailsCall.js`

**Issue.** The `orderTypeHelpers.setOrderType(order)` addition is correct and follows the same pattern used in other payment flows, but it has no relationship to BCRTR-1558 (engraving fallback rules). Mixing it into this branch muddies the blame history and makes rollback harder.

**Suggested fix.** Extract into a separate commit or, ideally, a separate PR. If it's already in `develop` via another branch, cherry-pick it; otherwise open a one-liner PR.

---

### Finding 8 — Missing newline at EOF in XML

**Severity:** info
**File:** `releases/2026_06_03/meta/custom-objecttype-definitions.xml:95`

**Issue.** The file ends without a trailing newline. Some XML parsers and `git diff` tools flag this.

**Suggested fix.** Add `\n` at end of file.

---

## What was done well

- **Row-level partial success** is the correct architecture for this use case. The previous all-or-nothing approach was the main operational pain point.
- **Centralising defaults** in `ENGRAVING_REQUEST_DEFAULTS` and `buildRequestBody` eliminates the scattered hardcoded values that were previously scattered across `engravingHelpers.js`.
- **Timestamped error accumulation** in `recordFailure` is a significant observability improvement over the single overwrite.
- **Comprehensive logging** throughout the job — the `Logger.info` coverage is thorough and will make future incident investigation much easier.
- **`parseEntries`/`serializeEntries`** are clean, well-named, and defensively written with per-entry try/catch.
- `buildEngravingPayload` removal is clean — confirmed no remaining callers in the codebase.

---

## Recurring patterns flagged

None identified as recurring across prior Baccarat reviews.

---

## Follow-ups

- [ ] Resolve set-of-string deduplication (Finding 1) — consider switching to `text` type
- [ ] Add deploy-time migration shim for in-flight `payload` COs (Finding 2)
- [ ] Revisit order-not-found deletion logic (Finding 3)
- [ ] Add `errorMessage` length cap in `recordFailure` (Finding 4)
- [ ] Verify `parseEntries(null)` is safe and/or initialise `rowsProcessed` in `addToQueue` (Finding 5)
- [ ] Standardise `const`/`let`/`var` (Finding 6)
- [ ] Move `setOrderType` change to separate commit/PR (Finding 7)
- [ ] Add trailing newline to XML (Finding 8)

---

## Sign-off

- [ ] All critical findings resolved
- [ ] All high findings resolved or accepted with rationale
- [ ] Tests cover the change (unit + integration where applicable)
- [ ] No new uncached SystemObjectMgr queries in loops
- [ ] ISML output encoding not disabled

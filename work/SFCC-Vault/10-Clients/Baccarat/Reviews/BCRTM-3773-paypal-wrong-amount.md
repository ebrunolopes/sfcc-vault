---
type: review
client: Baccarat
pr: BCRTM-3773
repo: OSFDigital/FR-BACCARAT-ITB-Rev-Sharing-SFRA-Migration-SFCC
branch: bugfix/BCRTM-3773
date: 2026-06-05
reviewer: Bruno Lopes
status: open
severity: medium
related-tsds: []
related-patterns: []
tags: [sfra/controller, integration, review]
---

# BCRTM-3773 — [EU] [ALL] [Paypal] Wrong amount charged by Paypal

## Summary

Fixes a PayPal amount mismatch where Adyen's `/paypalUpdateOrder` call was being rejected with error `14_0476` ("amount.value cannot be less than the original") on EU (GROSS taxation) sites. Root cause: the update request was sending `totalTax` even though for GROSS taxation the tax is already embedded inside item prices — causing Adyen to compute a higher reconciled total than what was sent in the original `/payments` call. The fix splits the tax-handling path by `TaxMgr.getTaxationPolicy()`, zeros out `taxTotal` for GROSS sites, and also fixes a related issue where bonus product line items had non-zero amounts in the PayPal line items array.

3 files changed, 199 lines: low-risk fix confined to the Adyen PayPal express payment flow.

---

## Findings

| # | Severity | Area | Finding | Status |
|---|---|---|---|---|
| 1 | medium | paypalHelper.js | `originalAmountValue` computed but unused in logic | open |
| 2 | medium | makeExpressPaymentsCall.js | Session fields `adyenPaypalLineItemsSum` + `adyenPaypalOriginalTax` stored but never read | open |
| 3 | low | paypalHelper.js | `new dw.value.Money(0, …)` used instead of imported `Money` | open |
| 4 | low | makeExpressPaymentsCall.js | Verbose `info_log` in critical checkout path | open |
| 5 | info | paypalHelper.js | Pre-existing `const` in `deliveryMethods.map` inconsistent with the `var` fix in shippingMethods.js | open |

---

### Finding 1 — `originalAmountValue` computed but unused in logic

**Severity:** medium
**Tags:** `#sfra/controller` `#integration`
**File:** `cartridges/app_baccarat/cartridge/adyen/utils/paypalHelper.js` — `createPaypalUpdateOrderRequest`

**Issue.** `originalAmountValue` is read from `session.privacy.adyenPaypalOriginalAmount` and `parseInt`-parsed, but the downstream calculation does not use it — `finalAmountValue = computedGrossValue` is assigned independently.

```js
var originalAmountValue = parseInt(session.privacy.adyenPaypalOriginalAmount, 10) || 0;
// … never referenced again except in AdyenLogs.info_log
var finalAmountValue = computedGrossValue;  // originalAmountValue not involved
```

**Why it matters.** The variable name implies a validation or guard comparison ("is the new amount within range of the original?") that never happens. A future reader will spend time looking for where it influences the logic. If validation was intentional but omitted, the mismatch could silently pass incorrect amounts.

**Suggested fix.** Either:
- Use it: add a guard log/assertion when `computedGrossValue` diverges significantly from `originalAmountValue`.
- Drop it: remove the variable and inline the value directly in the log string, or annotate clearly that it is logging-only.

```js
// Option A — logging-only, explicit intent
var originalAmountForLog = parseInt(session.privacy.adyenPaypalOriginalAmount, 10) || 0;

// Option B — drop the var, inline in log
", originalAmountFromSession: ".concat(session.privacy.adyenPaypalOriginalAmount || "n/a")
```

---

### Finding 2 — Session fields stored but never read

**Severity:** medium
**Tags:** `#sfra/controller` `#integration`
**File:** `cartridges/app_baccarat/cartridge/adyen/scripts/expressPayments/paypal/makeExpressPaymentsCall.js:88-94`

**Issue.** Two new session fields are written after the `/payments` call but do not appear to be read in any file in this diff:

```js
session.privacy.adyenPaypalLineItemsSum = lineItemsTotal;
session.privacy.adyenPaypalOriginalTax  = paymentRequest.amount.value - lineItemsTotal;
```

Only `adyenPaypalOriginalAmount` is read (in `paypalHelper.js`).

**Why it matters.** Dead session state adds confusion and wastes session storage. If these were part of a prior approach that was superseded, they should be removed. If they are used elsewhere (a file not in this diff), that should be documented.

**Suggested fix.** Confirm whether any other handler reads these fields. If not, remove them. If yes, add a comment pointing to the consumer.

---

### Finding 3 — `dw.value.Money` direct reference instead of imported `Money`

**Severity:** low
**Tags:** `#sfra/controller` `#integration`
**File:** `cartridges/app_baccarat/cartridge/adyen/utils/paypalHelper.js:49-50`

**Issue.**

```js
itemAmount = new dw.value.Money(0, itemAmount.getCurrencyCode()); // eslint-disable-line
vatAmount  = new dw.value.Money(0, vatAmount.getCurrencyCode());  // eslint-disable-line
```

`Money` is already imported at the top of the file (`var Money = require("dw/value/Money")`). The `eslint-disable-line` suppression is not needed when using the import.

**Suggested fix.**

```js
itemAmount = new Money(0, itemAmount.getCurrencyCode());
vatAmount  = new Money(0, vatAmount.getCurrencyCode());
```

---

### Finding 4 — Verbose `info_log` on critical checkout path

**Severity:** low
**Tags:** `#sfra/controller` `#observability`
**File:** `makeExpressPaymentsCall.js`, `paypalHelper.js`

**Issue.** Six `AdyenLogs.info_log` calls are added across the two files, all firing on every PayPal express checkout initiation and every shipping method fetch. Each call performs a string concatenation and I/O write.

**Why it matters.** `info_log` in SFCC writes to the custom log file on every invocation. Six extra writes per checkout step is noisy in production logs and makes real errors harder to spot.

**Suggested fix.** Once the PayPal amount bug is confirmed fixed in staging/prod, demote these to `debug_log` or remove the most redundant ones (the second delivery-methods log in `paypalHelper` duplicates information already in the first). Keep the reconciliation-delta log — that's the most useful signal.

---

### Finding 5 — Pre-existing `const` in `deliveryMethods.map`

**Severity:** info
**Tags:** `#sfra/controller` `#integration`
**File:** `cartridges/app_baccarat/cartridge/adyen/utils/paypalHelper.js` — `deliveryMethods.map` callback

**Issue.** The diff changes `const` → `var` in `shippingMethods.js` (presumably for SFCC script engine compatibility or linting), but the pre-existing `const { currencyCode, value } = shippingMethod.shippingCost;` destructuring inside the `deliveryMethods.map` callback is untouched. Not introduced by this diff, so not a blocker — but worth aligning in a follow-up.

---

## What was done well

- **NET vs GROSS taxation split is correct.** The `TaxMgr.TAX_POLICY_NET` check maps cleanly to the two Adyen error codes documented in the comments (14_0476 for GROSS over-counting, 14_0478 for NET mismatch). Comments name the exact error codes — invaluable for future debugging.
- **Bonus product zero-out is correct.** The `instanceof dw.order.ProductLineItem` guard before accessing `bonusProductLineItem` is necessary (other line item types don't have that property) and is properly placed.
- **`session.privacy` for cross-request state** is the correct SFCC pattern for passing values between the `/payments` and `/paypalUpdateOrder` calls.
- **`adjustedShippingTotalNetPrice` vs `adjustedShippingTotalGrossPrice`** selection is correct: for NET the shipping line must be net so tax-on-shipping isn't double-counted; for GROSS it's already embedded.
- **`var` fix in `shippingMethods.js`** is a clean, correct change.

---

## Follow-ups

- [ ] Confirm `adyenPaypalLineItemsSum` and `adyenPaypalOriginalTax` are read somewhere (or remove them)
- [ ] Replace `new dw.value.Money(0, …)` with imported `Money`
- [ ] Rename `originalAmountValue` → `originalAmountForLog` or remove if not used in logic
- [ ] After prod validation: demote or remove excess `info_log` calls

## Sign-off

- [ ] All critical findings resolved
- [ ] All high findings resolved or accepted with rationale
- [x] No new uncached SystemObjectMgr queries in loops
- [x] ISML output encoding not disabled
- [ ] Tests cover the change (unit + integration where applicable)

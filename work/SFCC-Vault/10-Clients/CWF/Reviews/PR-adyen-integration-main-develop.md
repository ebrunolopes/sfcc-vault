---
type: review
client: CWF
pr: adyen-integration
repo: OSFDigital/FR-CWF-IFB-Audit
branch: develop
base: main
date: 2026-05-31
reviewer: Bruno Lopes
status: open
severity: critical
related-tsds: []
related-patterns: []
tags: [#service, #security, #anti-pattern]
---

# Adyen Integration — main...develop

> Filename: `PR-adyen-integration-main-develop.md`

## Summary

This review covers the Adyen payment integration added to the `develop` branch of the CWF storefront. The diff introduces a full Adyen SFRA cartridge stack (`app_adyen_SFRA`, `int_adyen_SFRA`, `int_adyen_custom`, `int_adyen_webhooks`, `bm_adyen`) alongside custom CWF-specific helpers (`adyenOperationsCWF.js`, `paymentProviderHelper.js`, `adyenLocaleHelper.js`) and a set of custom event handlers that override the base webhook dispatcher for AUTHORISATION, CAPTURE, and REFUND events. The integration is architecturally well-structured and the CWF customizations (capture-expectation tracking, idempotency keys, per-webhook amount caching) show careful thought. However, three blockers require immediate attention before go-live: a runtime crash in `paymentUtils.js` that will silently break webhook processing, deletion of the Dalenys hook registration, and a REFUND handler state-machine bug that misclassifies failed refunds. The Baccarat processForm pattern is also reproduced here.

---

## Findings

| #   | Severity      | Area                                               | Finding                                                                           | Status |
| --- | ------------- | -------------------------------------------------- | --------------------------------------------------------------------------------- | ------ |
| 1   | 🔴 BLOCKER    | `int_adyen_webhooks/paymentUtils.js`               | `Object.values()` on SFCC Collection — silent runtime crash                       | open   |
| 2   | 🔴 BLOCKER    | `int_dalenys_sfra/package.json`                    | Dalenys hook registration deleted — breaks Dalenys payments                       | open   |
| 3   | 🔴 BLOCKER    | `int_adyen_custom/REFUND.js`                       | `setPaymentStatus(NOTPAID)` unconditional — failed refund marks order NOTPAID     | open   |
| 4   | 🟡 WARNING    | `int_adyen_SFRA/processForm.js`                    | Baccarat pattern reproduced — `setSessionPrivacy` NPE on billing-only save        | open   |
| 5   | 🟡 WARNING    | `int_adyen_webhooks/notify.js`                     | HMAC validation bypassed when key not configured                                  | open   |
| 6   | 🟡 WARNING    | `int_adyen_custom/AUTHORISATION.js` + `CAPTURE.js` | Minor-unit `/100` hardcode wrong for JPY/KWD currencies                           | open   |
| 7   | 🟡 WARNING    | `adyenOperationsCWF.js`                            | Idempotency-key fallback to random UUID breaks retry-safety                       | open   |
| 8   | 🟡 WARNING    | `adyenOperationsCWF.js`                            | Tight retry loop — no back-off, could trigger Adyen rate limiting                 | open   |
| 9   | 🟢 SUGGESTION | `int_adyen_SFRA/hooks.json`                        | OCAPI hook won't fire for SCAPI callers                                           | open   |
| 10  | 🟢 SUGGESTION | `int_adyen_webhooks/libAuthenticationUtils.js`     | `calculateHmacSignature` error path returns object, not string                    | open   |
| 11  | 🟢 SUGGESTION | `paymentProviderHelper.js`                         | `isAdyenPaymentInstrument` final fallback on `Adyen_pspReference` can false-match | open   |
| 12  | 🟢 SUGGESTION | `package.json`                                     | `mobx` dependency unusual — verify intended usage                                 | open   |
| 13  | 🟢 SUGGESTION | `int_adyen_webhooks/CAPTURE.js`                    | Commented-out original condition left in shipped code                             | open   |

---

### Finding 1 — `Object.values()` on SFCC Collection crashes webhook payment-instrument processing

**Severity:** 🔴 BLOCKER  
**Tags:** `#service` `#integration`  
**File:** `cartridges/int_adyen_webhooks/cartridge/utils/paymentUtils.js:16`

**Issue.** `handleAdyenPaymentInstruments` calls `Object.values(paymentInstruments)` on the `paymentInstruments` argument, which is a `dw.util.Collection` (Java-backed). In SFCC's Rhino/Nashorn engine, `Object.values()` on a Java collection returns the own enumerable JS properties of the wrapper object — not the contained items. The forEach loop will iterate over an empty or irrelevant set, `pi.getPaymentMethod()` will throw, and `foundAdyen` will always be `false`.

Additionally, `PaymentMgr.getPaymentMethod(pi.getPaymentMethod()).getPaymentProcessor()` has no null guard — if any payment method has no processor configured, this throws a NullPointerException before the `ID` access.

```js
// BROKEN — Object.values on a dw.util.Collection
Object.values(paymentInstruments).forEach(function (pi) {
  var processor = PaymentMgr.getPaymentMethod(pi.getPaymentMethod()).getPaymentProcessor().ID;
  ...
});

// FIX — use SFCC collection utilities
var collections = require('*/cartridge/scripts/util/collections');
collections.forEach(paymentInstruments, function (pi) {
  var paymentMethod = PaymentMgr.getPaymentMethod(pi.getPaymentMethod());
  if (!paymentMethod || !paymentMethod.getPaymentProcessor()) { return; }
  var processor = paymentMethod.getPaymentProcessor().ID;
  ...
});
```

**Why it matters.** This function is called from the AUTHORISATION webhook handler's Adyen-log update path. The silent failure means `foundAdyen` always returns `false` and the `Adyen_log` on payment transaction custom objects is never populated. Downstream OMS integrations that read `Adyen_log` will see stale/null data.

---

### Finding 2 — Dalenys hook registration deleted; Dalenys payments will break at runtime

**Severity:** 🔴 BLOCKER  
**Tags:** `#hook` `#integration`  
**File:** `cartridges/int_dalenys_sfra/package.json` (deleted)

**Issue.** The diff deletes `cartridges/int_dalenys_sfra/package.json`, which previously contained `{ "hooks": "./hooks.json" }`. SFCC discovers hook registrations by reading each cartridge's `package.json`. Without this file, the Dalenys payment processor hook (`app.payment.form.processor.dalenys_component` or similar) will no longer be registered, and Dalenys checkout will silently fail with an unresolved hook error.

At the same time, `package.json` at the root adds `int_dalenys` to the webpack `moduleBuildList`, suggesting Dalenys is *still active*, not being removed.

**Why it matters.** Any customer attempting to pay via Dalenys after deploy will get a payment error. This is a go-live blocker if Dalenys is still in scope.

**Action.** Restore `cartridges/int_dalenys_sfra/package.json`. If Dalenys is being intentionally removed, also remove it from the webpack build list and all checkout controller references.

---

### Finding 3 — REFUND webhook sets `PAYMENT_STATUS_NOTPAID` regardless of success

**Severity:** 🔴 BLOCKER  
**Tags:** `#custom-object` `#integration`  
**File:** `cartridges/int_adyen_custom/cartridge/eventHandlers/REFUND.js:62`

**Issue.** The `handle` function calls `order.setPaymentStatus(Order.PAYMENT_STATUS_NOTPAID)` before checking `isWebhookSuccessful`:

```js
function handle(params) {
  var order = params.order;
  var customObj = params.customObj;

  order.setPaymentStatus(Order.PAYMENT_STATUS_NOTPAID);   // ← runs unconditionally
  trackOrderChangeIfPossible(order, "REFUND notification received");

  if (isWebhookSuccessful(customObj)) {
    recordRefundedAmount(order, customObj);               // ← only success path here
  }
}
```

Adyen can send `REFUND` notifications with `success=false` when a refund is declined (e.g., funds already settled, card closed). For those events the order will be incorrectly marked NOTPAID even though the refund did not happen and the capture amount is still on the instrument.

```js
// FIX
function handle(params) {
  var order = params.order;
  var customObj = params.customObj;

  trackOrderChangeIfPossible(order, "REFUND notification received");

  if (isWebhookSuccessful(customObj)) {
    recordRefundedAmount(order, customObj);
    order.setPaymentStatus(Order.PAYMENT_STATUS_NOTPAID);
  }
}
```

**Why it matters.** A failed refund attempt would make the order appear unpaid in Business Manager and potentially trigger incorrect re-capture or OMS state transitions.

---

### Finding 4 — Baccarat pattern reproduced: `setSessionPrivacy` NPE on billing-only form submit

**Severity:** 🟡 WARNING  
**Tags:** `#sfra/controller` `#integration`  
**File:** `cartridges/int_adyen_SFRA/cartridge/adyen/scripts/hooks/payment/processor/middlewares/processForm.js:17`

**Issue.** `setSessionPrivacy` accesses `adyenPaymentFields.adyenFingerprint.value` directly without null-checking `adyenFingerprint`:

```js
function setSessionPrivacy(_ref) {
  var adyenPaymentFields = _ref.adyenPaymentFields;
  session.privacy.adyenFingerprint = adyenPaymentFields.adyenFingerprint.value;
                                     // ↑ throws TypeError if adyenFingerprint is null
}
```

This is called after the credit-card error guard but before any payment-method check. When the billing address step of checkout submits the form without the Adyen component having populated the fingerprint field, `adyenPaymentFields.adyenFingerprint` will be null, producing a `TypeError: Cannot read property 'value' of null`. The SFRA `processForm` hook call-site wraps this in a try/catch and returns `{ error: true }`, which manifests as a false payment validation error on the billing step.

This is the **exact same pattern** as Baccarat (`PR-baccarat-adyen-billing`). It is confirmed present in CWF.

```js
// FIX — guard before access
function setSessionPrivacy(paymentForm) {
  var adyenFingerprint = paymentForm.adyenPaymentFields && paymentForm.adyenPaymentFields.adyenFingerprint;
  if (adyenFingerprint) {
    session.privacy.adyenFingerprint = adyenFingerprint.value;
  }
}
```

**Why it matters.** Customers on a multi-step checkout who reach the billing address step before the Adyen component loads will see a payment error and be unable to proceed. This is a checkout conversion blocker on slow connections or when Adyen JS fails to load.

**Recurring pattern.** This same bug was found at Baccarat. Consider promoting to `40-Anti-Patterns/adyen-processform-fingerprint-null.md`.

---

### Finding 5 — HMAC webhook validation silently bypassed when HMAC key not configured

**Severity:** 🟡 WARNING  
**Tags:** `#service` `#security`  
**File:** `cartridges/int_adyen_webhooks/cartridge/notify.js:14`

**Issue.** If the `Adyen_hmacKey` site preference is empty or not set, `handleHmacVerification` returns `true` without performing any signature check:

```js
function handleHmacVerification(hmacKey, req) {
  if (hmacKey) {
    return checkAuth.validateHmacSignature(req);
  }
  return true;   // ← unauthenticated webhook accepted
}
```

An attacker who can reach the webhook endpoint (or an internal misconfiguration where the key hasn't been set in BM yet) can replay or forge any Adyen notification, triggering order state changes (AUTHORISATION, CAPTURE, REFUND) against arbitrary orders.

**Why it matters.** Webhook authentication is the only protection against forged payment notifications. Basic Auth alone is weaker (credentials may be shared across environments); HMAC provides cryptographic assurance the notification came from Adyen.

**Recommended fix.** Add an explicit configuration check at startup and log a fatal error / refuse to process if HMAC key is empty:

```js
function handleHmacVerification(hmacKey, req) {
  if (!hmacKey) {
    AdyenLogs.fatal_log('Adyen HMAC key not configured — rejecting notification for security');
    return false;
  }
  return checkAuth.validateHmacSignature(req);
}
```

---

### Finding 6 — Minor-unit `/100` hardcode incorrect for non-decimal currencies

**Severity:** 🟡 WARNING  
**Tags:** `#service` `#integration`  
**Files:**
- `cartridges/int_adyen_custom/cartridge/eventHandlers/AUTHORISATION.js:118`
- `cartridges/int_adyen_custom/cartridge/eventHandlers/CAPTURE.js:64`
- `cartridges/int_adyen_custom/cartridge/eventHandlers/REFUND.js:57`

**Issue.** All three handlers convert Adyen's minor-unit amounts to major units by dividing by 100:

```js
var captureAmount = captureMinorUnits / 100;   // hardcoded
```

This is correct for EUR, USD, GBP, CHF, etc. but produces wrong values for:
- **JPY, KRW** (0 decimal places) — off by 100×
- **KWD, BHD, OMR** (3 decimal places) — off by 10×

If CWF operates only in EUR/CHF/GBP this won't fire, but the value is stored in a custom attribute that feeds refund eligibility math. A wrong value here causes either under-refunds (silent loss of customer funds) or over-refunds (merchant loss).

**Fix.** Use `AdyenHelper.getCurrencyValueForApi` in reverse, or use a currency-aware conversion:

```js
// Option A: use Adyen SDK's own fractionDigits data
var Money = require('dw/value/Money');
var captureAmount = new Money(captureMinorUnits, currencyCode)
    .divide(Math.pow(10, Money.getCurrencyFractionDigits(currencyCode)));

// Option B: if AdyenHelper exposes it
var captureAmount = AdyenHelper.getValueFromMinorUnits(captureMinorUnits, currencyCode);
```

---

### Finding 7 — Idempotency-key fallback to random UUID breaks refund/capture retry safety

**Severity:** 🟡 WARNING  
**Tags:** `#service` `#integration`  
**File:** `cartridges/app_cwf/cartridge/scripts/helpers/adyenOperationsCWF.js:54`

**Issue.** `executeModificationCall` falls back to `UUIDUtils.createUUID()` when no `idempotencyKey` is supplied:

```js
var resolvedKey = idempotencyKey ? buildIdempotencyKey(idempotencyKey) : UUIDUtils.createUUID();
```

All three public functions (`refund`, `capture`, `cancelAuth`) do pass a stable key (based on `orderNo + suffix`). However, if a caller omits `referenceSuffix`, the key is e.g. `W0001234-R`, which is not unique across multiple partial refunds of the same order. A second partial refund on the same order without a distinct suffix will reuse the same idempotency key, and Adyen will return the first refund's response without creating a new one — silently dropping the second refund.

**Why it matters.** OMS-driven returns often generate multiple partial refund requests for the same order. If callers are expected to supply a unique suffix (e.g., return entry index), this must be documented and enforced.

**Fix.** Document the requirement; consider throwing if `referenceSuffix` is absent when `amount < orderTotal`.

---

### Finding 8 — Tight retry loop with no back-off in `executeModificationCall`

**Severity:** 🟡 WARNING  
**Tags:** `#service` `#perf`  
**File:** `cartridges/app_cwf/cartridge/scripts/helpers/adyenOperationsCWF.js:63`

**Issue.** The retry loop calls the Adyen service `MAX_API_RETRIES` times in a tight loop with no delay:

```js
for (var retry = 0; retry < constants.MAX_API_RETRIES; retry++) {
    callResult = service.call(JSON.stringify(requestObject));
    if (callResult && callResult.isOk()) { break; }
}
```

If `MAX_API_RETRIES` is 3+ and the Adyen API is returning 429 (rate limited) or 5xx, the retries will happen within milliseconds of each other, violating Adyen's retry guidelines and potentially triggering a circuit-breaker block.

**Fix.** Add exponential back-off using `java.lang.Thread.sleep` or limit retries to 1 for synchronous contexts (job step vs. storefront request).

---

### Finding 9 — OCAPI hook won't fire for SCAPI callers

**Severity:** 🟢 SUGGESTION  
**Tags:** `#ocapi` `#deprecation`  
**File:** `cartridges/int_adyen_SFRA/cartridge/adyen/scripts/hooks.json:36`

**Issue.** The hook `dw.ocapi.shop.basket.payment_methods.modifyGETResponse` is an OCAPI hook. If CWF has already migrated checkout to SCAPI (or plans to), this hook will not fire for SCAPI `GET /baskets/{id}/payment-methods` calls. Payment method filtering/customization done here will be invisible to SCAPI callers.

**Why it matters.** If both OCAPI and SCAPI flows are active simultaneously (hybrid migration), payment method availability may differ between channels.

**Action.** Determine whether CWF uses SCAPI for payment methods. If yes, implement the equivalent filtering in a SCAPI hook or custom endpoint.

---

### Finding 10 — `calculateHmacSignature` error path returns an object, not a string

**Severity:** 🟢 SUGGESTION  
**Tags:** `#service` `#security`  
**File:** `cartridges/int_adyen_webhooks/cartridge/libs/libAuthenticationUtils.js:58`

**Issue.** On error, `calculateHmacSignature` returns `{ error: true }` instead of throwing or returning an empty string. `compareHmac` receives this object; `hmacSignature.length` is `undefined`; `undefined !== merchantSignature.length` → returns `false` → HMAC check fails → 403. The end result is safe (notification rejected), but the error path is misleading and may produce confusing log output.

**Fix.** Throw from `calculateHmacSignature` on error and let `validateHmacSignature` catch and return `false`. This makes the control flow explicit.

---

### Finding 11 — `isAdyenPaymentInstrument` final fallback can false-match non-Adyen instruments

**Severity:** 🟢 SUGGESTION  
**Tags:** `#service` `#integration`  
**File:** `cartridges/app_cwf/cartridge/scripts/helpers/paymentProviderHelper.js:60`

**Issue.** After checking method name and processor ID, the function falls through to `return hasAdyenReference` as a catch-all:

```js
return hasAdyenReference;   // could be true for any instrument with Adyen_pspReference set
```

If a non-Adyen instrument happens to have `order.custom.Adyen_pspReference` populated (e.g., from a prior Adyen order on the same order object, or a data migration), it would be mis-identified as an Adyen instrument, causing `getPaymentProvider` to return `ADYEN` when it shouldn't.

**Fix.** Remove the final `hasAdyenReference` fallback or scope it to only fire after confirming `paymentMethod` matches an Adyen method prefix.

---

### Finding 12 — `mobx` dependency added to production bundle

**Severity:** 🟢 SUGGESTION  
**Tags:** `#sfra/isml` `#perf`  
**File:** `package.json:124`

**Issue.** `mobx: ^6.15.3` was added to `dependencies` (not `devDependencies`). MobX is a reactive state management library (33 kB gzipped) typically used with React/Vue. SFCC already has Vue 2 in this project; adding MobX alongside Vue's reactivity system is unusual. Verify this is intentional and not a dependency that was added accidentally. If needed only in one component, consider whether Vue's own reactive primitives cover the use case.

---

### Finding 13 — Commented-out original condition left in base CAPTURE handler

**Severity:** 🟢 SUGGESTION  
**Tags:** `#service` `#integration`  
**File:** `cartridges/int_adyen_webhooks/cartridge/eventHandlers/CAPTURE.js:12`

**Issue.** The original Adyen condition was replaced but left as a comment:

```js
//if (isWebhookSuccessful(customObj) && order.status.value === Order.ORDER_STATUS_CANCELLED) {
if (isWebhookSuccessful(customObj)) { // OSF CUSTOMIZATION
```

This ships dead commented code into production. The intent (expand the condition) is correct, but the comment creates confusion about why the original guard existed (it only un-cancelled previously-cancelled orders on capture, not all orders).

**Fix.** Remove the comment line; keep the `// OSF CUSTOMIZATION` marker on the active line if needed for diff tracking.

---

## What was done well

- **Idempotency architecture** in `adyenOperationsCWF.js` is well-reasoned: stable reference keys derived from `orderNo + suffix`, sanitized and truncated to Adyen's 64-char limit, with explicit documentation of the retry-safety contract.

- **Per-webhook amount caching** (capture history, refund history keyed by pspReference) is correct and prevents double-counting on webhook redelivery. The JSON-based history store is pragmatic given SFCC's custom attribute constraints.

- **CWF AUTHORISATION override** correctly sets `CONFIRMATION_STATUS_NOTCONFIRMED` after placement and includes a clear comment explaining the CWF-specific flow (status stays NOTCONFIRMED until the CWF import job confirms order lines). This is exactly the kind of intentional customization that should be documented.

- **PayPal force-treated as separate-capture** regardless of the `operations` field — the comment in `recordCaptureExpectation` explains the observed Adyen behavior that drove this exception. Solid defensive coding.

- **`adyenLocaleHelper.js`** is cleanly separated from payment logic, has accurate SDK locale references, and correctly warns that `countryCode` must never use the mapped value.

- **`handleCustomObject.js` (CWF override)** correctly intercepts only the three overridden event codes and delegates everything else to the base module — minimal surface area, clean separation.

- **Gift certificate redemption** in `adyenHelper.js` override is wrapped in try/catch with re-throw, ensuring payment failures surface correctly rather than silently succeeding with an unredeemed certificate.

---

## Recurring patterns flagged

- **Finding 4** (processForm fingerprint NPE) is the **same bug** found at Baccarat. Tag `#recurring`. Promote to `~/work/SFCC-Vault/40-Anti-Patterns/adyen-processform-fingerprint-null.md`.

---

## Follow-ups

- [ ] Fix `Object.values()` → `collections.forEach()` in `paymentUtils.js` (Finding 1)
- [ ] Restore or explicitly remove `int_dalenys_sfra/package.json` with team decision (Finding 2)
- [ ] Move `setPaymentStatus(NOTPAID)` inside `isWebhookSuccessful` block in REFUND handler (Finding 3)
- [ ] Guard `adyenPaymentFields.adyenFingerprint` before `.value` access (Finding 4)
- [ ] Confirm HMAC key is configured in all environments; add hard-fail if empty (Finding 5)
- [ ] Replace `/100` hardcode with currency-aware conversion (Finding 6)
- [ ] Clarify `referenceSuffix` contract for partial refunds (Finding 7)
- [ ] Add retry back-off or reduce `MAX_API_RETRIES` for synchronous paths (Finding 8)
- [ ] Assess OCAPI vs SCAPI payment-methods hook coverage (Finding 9)
- [ ] Promote Baccarat processForm pattern to `40-Anti-Patterns/`

---

## Sign-off

- [ ] All critical findings resolved
- [ ] All high findings resolved or accepted with rationale
- [ ] `paymentUtils.js` SFCC collection iteration verified in sandbox
- [ ] Dalenys payment flow re-tested after package.json decision
- [ ] REFUND webhook tested with `success=false` payload
- [ ] HMAC key configured in all target environments

---

## Summary Report

> Copy this section into the PR comment.

### Adyen Integration Review — main...develop

**Verdict: REQUEST CHANGES** — 3 blockers require fixes before merge.

#### 🔴 Blockers (3)

1. **`paymentUtils.js` — `Object.values()` on SFCC Collection** (`int_adyen_webhooks/cartridge/utils/paymentUtils.js:16`): `Object.values()` does not iterate SFCC `dw.util.Collection` objects in Rhino/Nashorn — the loop runs on an empty set, `pi.getPaymentMethod()` will throw, and `foundAdyen` always returns false. Replace with `collections.forEach()` and add a null guard on `getPaymentProcessor()`.

2. **Dalenys hook registration deleted** (`int_dalenys_sfra/package.json` removed): Removing this file deregisters all Dalenys payment hooks. Dalenys checkout will fail silently at runtime while the cartridge is still in the webpack build list. Restore the file or explicitly decommission Dalenys.

3. **REFUND handler sets `PAYMENT_STATUS_NOTPAID` unconditionally** (`int_adyen_custom/eventHandlers/REFUND.js:62`): `setPaymentStatus(NOTPAID)` runs before the `isWebhookSuccessful` check — a declined refund notification will mark the order as unpaid. Move inside the success block.

#### 🟡 Warnings (5)

4. **Baccarat processForm pattern reproduced** (`processForm.js:17`): `setSessionPrivacy` accesses `.adyenFingerprint.value` without null check. On billing-only form submits (no Adyen component loaded), this throws a TypeError → false validation failure → checkout blocked. Previously found at Baccarat.

5. **HMAC key unconfigured → webhook unauthenticated** (`notify.js:14`): If `Adyen_hmacKey` is empty, all webhook notifications are accepted without signature verification. Add hard-fail when key is absent.

6. **`/100` minor-unit conversion hardcoded** (AUTHORISATION/CAPTURE/REFUND handlers): Wrong for JPY (0 decimals) and KWD/BHD (3 decimals). Use currency-aware conversion.

7. **Idempotency-key omission not safe for multi-partial-refund** (`adyenOperationsCWF.js`): If `referenceSuffix` is omitted on a second partial refund for the same order, the key collides with the first refund's key — Adyen silently returns the first response. Document and enforce unique suffix per refund.

8. **Tight retry loop** (`adyenOperationsCWF.js`): `MAX_API_RETRIES` retries with no delay will hammer a rate-limited Adyen API. Add exponential back-off.

#### 🟢 Suggestions (5)

9. OCAPI payment-methods hook won't fire for SCAPI callers — assess coverage gap.
10. `calculateHmacSignature` error path returns `{ error: true }` object instead of throwing — confusing but safe.
11. `isAdyenPaymentInstrument` final `hasAdyenReference` fallback can false-match non-Adyen instruments.
12. `mobx` added to production dependencies — verify intentional; Vue's reactivity may cover the use case.
13. Commented-out original CAPTURE condition left in shipped code — remove dead comment.

#### Positive highlights

The idempotency key design, per-webhook amount caching with pspReference-keyed dedup, the CWF AUTHORISATION override (NOTCONFIRMED flow), and the PayPal separate-capture exception are all well-engineered. The `adyenLocaleHelper` and `paymentProviderHelper` are clean additions.

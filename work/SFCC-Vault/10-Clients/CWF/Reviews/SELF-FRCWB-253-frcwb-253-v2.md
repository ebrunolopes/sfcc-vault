---
type: self-review
client: CWF
identifier: FRCWB-253
repo: OSFDigital/FR-CWF-IFB-Audit
branch: feature/FRCWB-253_v2
base: develop
date: 2026-05-28
reviewer: Claude (sfcc-self-review)
status: open
last-iteration: 2
last-iteration-date: 2026-05-28
last-mode: auto
verdict: fix-blockers
sections-run: [1, 2, 3, 4, 5, 6, 7, 8, 9]
sections-skipped: []
related-tsds: []
tags: [sfra/isml, integration, draft]
---

## Iteration 1 — 2026-05-28
*Mode: auto. Sections ran: §1 §2 §3 §4 §5 §6 §7 §8 §9. All optional sections auto-triggered.*

---

### Diff summary

| File | Change |
|---|---|
| `app_cwf/scripts/adyen/adyenLocaleHelper.js` | **NEW** — locale mapping + translation override helper |
| `app_cwf/scripts/helpers/gtmHelpers.js` | Refactor `position` null-guard to use SFCC `empty()` |
| `app_cwf/scripts/jobsteps/order/ImportOrderConfirmation.js` | Remove `setConfirmationStatus` / `setPaymentStatus` after cancel |
| `app_cwf/scripts/jobsteps/order/ImportOrderShipment.js` | Same removal |
| `app_cwf/templates/default/adyen/adyenExpressMetadata.isml` | Use locale helper; set `countryCode` + `translations` on `window` |
| `app_cwf/templates/default/checkout/billing/adyenComponentForm.isml` | Same locale/translation wiring |
| `int_adyen_SFRA/adyen/scripts/payments/adyenGetPaymentMethods.js` | Use locale helper for `shopperLocale` |
| `int_adyen_custom/adyen/scripts/payments/paymentFromComponent.js` | Collapse cancellation handler — remove null-guard around `failOrder` |
| `int_adyen_custom/templates/.../paymentOptionsTabs.isml` | Remove outer null-guard on `applicablePaymentMethods`; indent flatten |

---

### §1 — Correctness & Business Logic

**🔴 B1 — `paymentFromComponent.js:153` — `failOrder(null)` crash on missing orderToken**

The original code handled a documented real-world edge case: the frontend cancel callback
occasionally drops `orderToken` (Apple Pay / PayPal dismissed before SDK resolves). Without
`orderToken`, `OrderMgr.getOrder(ref, undefined)` returns `null`. The new code calls
`failOrder(order)` with no null-check, which will throw and surface a 500 to the shopper.

The removed comment was not just documentation — it was the rationale for defensive code that
was observed to be necessary in production.

```js
// Fix: restore null-check (or at minimum guard failOrder)
order = OrderMgr.getOrder(reqDataObj.merchantReference, reqDataObj.orderToken);
if (order) {
    failOrder(order);
} else {
    AdyenLogs.error_log(
        'paymentFromComponent cancellation: order not found (merchantReference='
            .concat(reqDataObj.merchantReference || '?', ', orderToken present=',
                    !!reqDataObj.orderToken, ')')
    );
}
```

---

**🔴 B2 — `paymentOptionsTabs.isml:3` — null guard on `applicablePaymentMethods` removed**

Original outer `<isif>` guarded against `pdict.order.billing.payment` being null/undefined
(e.g. guest users before entering payment step, error paths, edge cases during order review).
The new code goes straight to `<isloop items="${pdict.order.billing.payment.applicablePaymentMethods}">`,
which throws a script exception if `pdict.order.billing.payment` is null.

```isml
{{Fix: restore the guard}}
<isif condition="${pdict.order.billing.payment && pdict.order.billing.payment.applicablePaymentMethods}">
    <isloop items="${pdict.order.billing.payment.applicablePaymentMethods}" var="paymentOption" status="loopState">
        ...
    </isloop>
</isif>
```

Also: **typo** on the same line — `status="loopSate"` → `status="loopState"`.

---

### §2 — SFCC Platform Correctness

**🟡 W1 — Cross-cartridge `require` from `int_adyen_SFRA` → `app_cwf`**

`int_adyen_SFRA/adyen/scripts/payments/adyenGetPaymentMethods.js` now does:
```js
var adyenLocaleHelper = require('*/cartridge/scripts/adyen/adyenLocaleHelper');
```
The `*` wildcard resolves via the active cartridge path at runtime. For this to resolve to
`app_cwf`, `app_cwf` must appear **before** `int_adyen_SFRA` in the site cartridge path.

Verify in BM → Administration → Sites → Manage Sites → [site] → Settings → Cartridge Path.
If `int_adyen_SFRA` is ever placed before `app_cwf`, this require will fail silently with a
module-not-found error and break the payment methods call.

→ Consider moving the helper to a shared cartridge (e.g., `int_adyen_custom`) that is
unambiguously upstream of `int_adyen_SFRA`, or document the path dependency explicitly.

---

### §3 — Security & Compliance

**🟡 W2 — `encoding="off"` for `adyenTranslationsJson` in ISML — safe now, fragile long-term**

Both templates use:
```isml
window.translations = <isprint value="${adyenTranslationsJson}" encoding="off"/>;
```

Currently safe because `adyenTranslationsJson` is `JSON.stringify` of hardcoded constants from
`TRANSLATION_OVERRIDES`. `JSON.stringify` escapes `"` and `\`, but it does **not** escape
`</script>`, meaning a translation string containing `</script>` would break out of the script
block (classic JSON-in-HTML injection).

→ Add an inline comment to both templates explaining why `encoding="off"` is safe:
```isml
<isprint value="${adyenTranslationsJson}" encoding="off"/><!-- safe: JSON.stringify of hardcoded constants, no user input -->
```
→ Add a matching note in `TRANSLATION_OVERRIDES` in `adyenLocaleHelper.js` warning that
translation strings must not contain `</` sequences.

No CSRF or PII issues in this diff.

---

### §4 — Payments / Orders / OMS Safety

**🔴 B1 (duplicate — see §1)** — `failOrder(null)` crash in cancellation path.

**🟡 W3 — `ImportOrderConfirmation.js` + `ImportOrderShipment.js` — removed status resets after cancel**

Both job steps previously reset:
```js
order.setConfirmationStatus(Order.CONFIRMATION_STATUS_NOTCONFIRMED);
order.setPaymentStatus(Order.PAYMENT_STATUS_NOTPAID);
```
immediately after `OrderMgr.cancelOrder()`. The removed comment explicitly documented that
`OrderMgr.cancelOrder` does **not** touch `confirmationStatus` or `paymentStatus`, so without
these resets cancelled orders retain whatever status they had at cancellation time — typically
`CONFIRMED` + `PAID` — giving a misleading picture in BM reporting and downstream OMS feeds.

If this removal is **intentional** (e.g., another job or webhook now owns these resets, or the
downstream OMS prefers the prior status for reconciliation), add a comment explaining the
decision. If it's accidental, restore the two lines in each file.

**Idempotency** — the locale helper changes do not affect idempotency; no double-charge risk
introduced.

---

### §5 — Performance & Caching

No performance concerns. `adyenLocaleHelper` is a pure in-memory computation (two `require`s and
a map lookup). Called once per request in template rendering. `JSON.stringify` of a small static
object is negligible.

No N+1, no uncached `SystemObjectMgr` queries, no synchronous HTTP introduced.

---

### §6 — Accessibility (WCAG 2.1 AA)

ISML changes are confined to `<isscript>` blocks and `<script>` variable assignments.
No structural HTML was modified. No accessibility impact.

---

### §7 — Testing & Coverage

**🟡 W4 — `adyenLocaleHelper.js` has no unit tests**

This is a new, testable pure-function module. It should have a `test/unit/app_cwf/scripts/adyen/adyenLocaleHelper.js` test file covering:
- `getAdyenLocale` — known mapped locale (e.g. `de_AT` → `de_DE`), unmapped locale passthrough, falsy inputs (`null`, `""`, `undefined`) → `en_US`
- `getAdyenTranslations` — locale with overrides returns correct shape `{ [adyenLocale]: {...} }`, locale without overrides returns `{}`

**🟡 W5 — `paymentFromComponent.js` cancellation change — no test update**

The behaviour change (removing the null-guard) is significant enough to warrant a test or at
minimum updating an existing test to assert the new behaviour.

---

### §8 — Deprecations & Modernization

No pipelines, legacy OCAPI hooks, or `HTTPClient` usage introduced. `var` declarations are
consistent with the existing codebase style for SFCC server-side JS. No modernization concerns.

---

### §9 — Code Quality & Maintainability

- `adyenLocaleHelper.js` is well-structured: clear JSDoc, named exports, good comments. ✓
- `adyenExpressMetadata.isml` and `adyenComponentForm.isml`: the `<isscript>` block is
  consistent with SFRA patterns. ✓
- Typo: `paymentOptionsTabs.isml` — `status="loopSate"` (see B2 above).
- The removal of explanatory comments in `paymentFromComponent.js` and both job steps reduces
  maintainability. Restore or replace them even if the logic changes.
- `gtmHelpers.js` — the `empty()` refactor is valid SFCC idiom. Equivalent behaviour to the
  original null check. ✓

---

### Finding Index

| ID | Severity | File | Summary |
|---|---|---|---|
| B1 | 🔴 Blocker | `paymentFromComponent.js:153` | `failOrder(null)` crash when orderToken missing |
| B2 | 🔴 Blocker | `paymentOptionsTabs.isml:3` | Null guard removed; `<isloop>` on potentially null `applicablePaymentMethods` |
| W1 | 🟡 Warning | `adyenGetPaymentMethods.js:29` | Cross-cartridge `require` depends on undocumented cartridge path order |
| W2 | 🟡 Warning | Both ISML templates | `encoding="off"` + JSON-in-HTML — safe now, needs comment to stay safe |
| W3 | 🟡 Warning | `ImportOrderConfirmation.js`, `ImportOrderShipment.js` | `setConfirmationStatus`/`setPaymentStatus` removed — BM/OMS reporting risk |
| W4 | 🟡 Warning | `adyenLocaleHelper.js` | New module has no unit tests |
| W5 | 🟡 Warning | `paymentFromComponent.js` | Cancellation behaviour change has no test coverage |
| S1 | 🟢 Suggest | `paymentOptionsTabs.isml:3` | Typo `loopSate` → `loopState` |
| S2 | 🟢 Suggest | `paymentFromComponent.js`, both job files | Restore inline comments explaining removed guards |

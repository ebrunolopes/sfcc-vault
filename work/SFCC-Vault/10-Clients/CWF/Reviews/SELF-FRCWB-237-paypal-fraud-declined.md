---
type: review
client: CWF
pr: FRCWB-237
repo: OSFDigital/FR-CWF-IFB-Audit
branch: feature/FRCWB-237_v2
date: 2026-06-03
reviewer: Bruno Lopes
status: open
severity: high
related-tsds: []
related-patterns: []
tags: [sfra/controller, integration, review]
---

# FRCWB-237 — PayPal fraud block: frontend issue when payment is declined

> Filename: `SELF-FRCWB-237-paypal-fraud-declined.md`

## Summary

Fixes a frontend crash in the Adyen PayPal component when a payment is blocked for fraud. Root cause: `component.handleError()` in the Adyen SDK throws (`can't access property name, e is undefined`) when PayPal is refused, preventing error messages and redirects from reaching the user. The fix overrides the client-side `helpers.js` via `NormalModuleReplacementPlugin`, intercepts the REFUSED result before touching the SDK error handler, shows an inline error banner, remounts the PayPal button, and ensures `failOrder` is called for all payment methods (not just express). Risk level: medium-high — changes touch the Adyen payment core and affect all checkout flows.

## Findings

| #   | Severity | Area        | Finding                                                                                                         | Status |
| --- | -------- | ----------- | --------------------------------------------------------------------------------------------------------------- | ------ |
| 1   | high     | integration | `handlePaymentFromComponent.js`: redirect guard removed — now fires for ALL redirectUrls                        | open   |
| 2   | high     | integration | `adyenCheckout.js`: error message override fires on `adyenErrorMessage` presence alone, ignoring `result.error` | open   |
| 3   | medium   | integration | webpack `NormalModuleReplacementPlugin` regex too broad — `/helpers(\.js)?$/`                                   | open   |
| 4   | medium   | integration | `helpers.js`: `async/await` — Babel config not verified                                                         | open   |
| 5   | low      | integration | `helpers.js`: 500ms `setTimeout` for remount is an arbitrary magic number                                       | open   |
| 6   | info     | integration | Comment in `paymentFromComponent.js` reads as if old behaviour was intentional                                  | open   |

---

### Finding 1 — `handlePaymentFromComponent.js`: overly permissive redirect condition

**Severity:** high
**Tags:** `#integration` `#sfra/controller`
**File:** `cartridges/int_adyen_custom/cartridge/adyen/scripts/showConfirmation/handlePaymentFromComponent.js`

**Issue.**
```diff
- if (redirectUrl && redirectUrl.indexOf("stage=placeOrder") > -1) {
+ if (redirectUrl) {
```
The `stage=placeOrder` guard was intentional — it scoped the rewrite to the order confirmation stage only. Removing it means **any** `redirectUrl` passed through the form will be silently rewritten to `Checkout-Begin?stage=payment`. This includes 3DS redirect URLs, partial-payment confirmation flows, and any other flow that legitimately sets a `redirectUrl` to something other than `stage=placeOrder`.

**Why it matters.**
A 3DS redirect URL entering this function would be overwritten, sending the shopper to the payment step instead of completing 3DS authentication — silent breakage of an entire auth flow.

**Suggested fix.**
Instead of removing the guard, extend it to also allow refused-payment redirects:
```js
if (redirectUrl && (
    redirectUrl.indexOf("stage=placeOrder") > -1 ||
    redirectUrl.indexOf("stage=payment") > -1
)) {
```
Or — if the refused-redirect URL set in `paymentFromComponent.js` already includes `stage=payment` — the existing guard just needs to be confirmed as covering that case.

---

### Finding 2 — `adyenCheckout.js`: error message override ignores `result.error`

**Severity:** high
**Tags:** `#integration`
**File:** `cartridges/int_adyen_custom/cartridge/adyen/scripts/payments/adyenCheckout.js:149-153`

**Issue.**
```js
if (result && result.adyenErrorMessage) {
    result.adyenErrorMessage = Resource.msg("confirm.error.declined", "checkout", null) || ...;
}
```
This replaces `adyenErrorMessage` on **any** result that carries that field — not only error results. Some Adyen responses may legitimately include an `adyenErrorMessage` field alongside non-error payloads. More importantly, the original Adyen-returned error string (e.g. `"Fraud detected by Adyen risk rules"`) is discarded without logging, which hinders incident investigation.

**Why it matters.**
Silently replacing operational error messages makes post-incident debugging harder. It also risks masking valid Adyen action responses.

**Suggested fix.**
```js
if (result && result.error && result.adyenErrorMessage) {
    AdyenLogs.error_log("Adyen raw error:", result.adyenErrorMessage);
    result.adyenErrorMessage = Resource.msg("confirm.error.declined", "checkout", null)
        || Resource.msg("error.invalid.payment.msg", "checkout", null);
}
```

---

### Finding 3 — webpack `NormalModuleReplacementPlugin` regex too broad

**Severity:** medium
**Tags:** `#integration`
**File:** `webpack.config.js:133`

**Issue.**
```js
new webpack.NormalModuleReplacementPlugin(
    /helpers(\.js)?$/,
    function (resource) { ...
```
The pattern `/helpers(\.js)?$/` matches **any** module whose resolved path ends in `helpers` or `helpers.js` across the entire dependency graph. The context-based guard (`resource.context.includes("app_adyen_SFRA")`) mitigates this, but it's fragile — if module resolution changes, a non-Adyen `helpers.js` could get silently replaced or the correct Adyen one could be skipped.

**Suggested fix.** Use a fully-anchored path pattern:
```js
/app_adyen_SFRA[/\\]cartridge[/\\]client[/\\]default[/\\]js[/\\]adyen[/\\]checkout[/\\]helpers(\.js)?$/
```
This removes the need for the context-check guard entirely.

---

### Finding 4 — `helpers.js`: `async/await` without confirmed Babel config

**Severity:** medium
**Tags:** `#integration`
**File:** `cartridges/int_adyen_custom/cartridge/client/default/js/adyen/checkout/helpers.js:59`

**Issue.**
`paymentFromComponent` is declared as `async function`. If the project's Babel config does not include `@babel/plugin-transform-async-to-generator` (or `@babel/preset-env` targeting legacy browsers), this will throw at runtime in Safari < 10.1 or IE11.

**Why it matters.** CWF supports EU markets including Germany (DE) and Italy (IT), where IE11 usage may still exist depending on SLAs.

**Suggested fix.** Confirm `.babelrc` / `babel.config.js` targets. If `async/await` is already used in `app_adyen_SFRA` client code, this is fine — just verify explicitly and add a comment confirming it.

---

### Finding 5 — `helpers.js`: 500ms `setTimeout` for remount is arbitrary

**Severity:** low
**Tags:** `#integration`
**File:** `cartridges/int_adyen_custom/cartridge/client/default/js/adyen/checkout/helpers.js:55`

**Issue.**
```js
setTimeout(remountPaypalComponent, 500);
```
The 500ms delay is an empirical guess. On slow devices or congested JS threads, unmount may not have settled and `mount()` will fail silently (caught by the empty catch block).

**Suggested fix.** Use a `Promise`-based approach or check the component state before remounting. At minimum, log the caught error in the remount catch so regressions are detectable.

---

### Finding 6 — Comment in `paymentFromComponent.js` reads as if old behaviour was intentional

**Severity:** info
**Tags:** `#integration`
**File:** `cartridges/int_adyen_custom/cartridge/adyen/scripts/payments/paymentFromComponent.js:188-195`

**Issue.**
The comment block reads:
> `// Express methods (ApplePay, GooglePay, AmazonPay) required this to handle their decline flow; extending it to all methods...`

This implies the old `expressMethods`-only guard was the correct design. A reader might revert it thinking they're restoring intentional behaviour.

**Suggested fix.** Reframe:
```js
// Previously only failed the order for express methods; now extended to all
// payment methods so the basket is always restored on any refused payment.
failOrder(order);
```

---

## What was done well

- **Correct architectural decision:** intercepting before `component.handleError()` is the right fix — the SDK crash is in third-party code and can't be patched.
- **`NormalModuleReplacementPlugin` approach:** cleaner than forking the entire `app_adyen_SFRA` client cartridge; scoped to `app_cwf` and `app_EMEA` only.
- **Localization coverage:** `confirm.error.declined` added to all 7 locale property files (EN, DE, ES_ES, FR, IT_IT, NL, PT_PT).
- **`failOrder` extended to all methods:** correct — the basket must always be restored on refusal, not only for express methods.
- **PayPal overlay recovery pattern:** unmount → show error banner → remount (with delay) is the right sequence to close the PayPal popup and restore the button.
- **webpack aliases:** `adyen-sfra-client` and `adyen-sfra-config` added cleanly to `package.json` — makes the intent of the override explicit.

## Recurring patterns flagged

- The overly-broad redirect condition (Finding 1) echoes a similar pattern seen in previous Adyen customizations where guards introduced by the base cartridge are simplified away. Worth a note in `40-Anti-Patterns/` if it recurs.

## Follow-ups

- [ ] Fix Finding 1: scope redirect rewrite to `stage=placeOrder` OR `stage=payment` only
- [ ] Fix Finding 2: add `result.error` guard + log original error before replacing
- [ ] Fix Finding 3: tighten webpack regex to full module path
- [ ] Verify Finding 4: confirm Babel config handles `async/await`
- [ ] Test 3DS payment flow end-to-end to confirm Finding 1 fix doesn't break it
- [ ] Test PayPal happy path after fix

## Sign-off

- [ ] All critical findings resolved
- [ ] All high findings resolved or accepted with rationale
- [ ] Tests cover the change (unit + integration where applicable)
- [ ] No new uncached SystemObjectMgr queries in loops
- [ ] ISML output encoding not disabled

# Apple Pay Express (Adyen) Implementation Plan — Revised

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Apple Pay Express checkout for the Baccarat storefront (cart + PDP) using the Adyen cartridge. The feature was partially implemented on branch `feature/BCRTR-1611` using an "optin popin" pattern (matching PayPal). Three bugs remain before the feature is functional.

**Architecture:** Apple Pay uses a trigger-button → modal flow, matching PayPal Express. When a user clicks the Apple Pay trigger button (`applePayExpressOptinPopinTrigger.isml`), `expressOptinPopin.js` fires an AJAX call to `Cart-ApplePayExpressOptinPopin`, which renders the terms modal (`applePayExpressOptinPopin.isml`). Inside the modal is `applePayExpressButton.isml`, which sets all Adyen window vars and mounts the Apple Pay button into a `.applepay` div. `expressPayments.js` is re-loaded fresh each time the modal opens (old script tags removed first), so double-mount is avoided without extra guards.

**Tech Stack:** SFCC 24.6 · SFRA 7.1 · Adyen Web SDK · Webpack (`npm run ci`) · cartridges: `app_baccarat`, `int_adyen_SFRA`, `app_adyen_SFRA`

---

## What `feature/BCRTR-1611` already implemented

These are **done** — do not re-implement:

| File | Status |
|------|--------|
| `components/expressOptinPopin.js` | ✅ New unified handler (replaces `payPalExpressOptinPopin.js`) |
| `main.js` | ✅ Switched to `expressOptinPopin` |
| `payPalExpressOptinPopin.isml` | ✅ CSS classes genericised |
| `payPalExpressOptinPopinTrigger.isml` | ✅ Uses generic `js-open-express-optin-modal` |
| `applePayExpressOptinPopin.isml` | ✅ Apple Pay modal structure complete |
| `applePayExpressOptinPopinTrigger.isml` | ✅ Apple Pay trigger button |
| `applePayExpressButton.isml` | ✅ Adyen SDK setup in modal (but has a bug — see Task 2) |
| `Cart.js` | ✅ `Cart-ApplePayExpressOptinPopin` route added |
| `cart.isml` | ✅ Apple Pay trigger on cart (mobile + desktop) |
| `buttonsBlockPDP.isml` | ✅ Apple Pay trigger on PDP Revamp |
| `adyenConfigs.js` | ✅ `isApplePayExpressEnabled` + `isApplePayExpressOnPdpEnabled` functions added (but have bugs — see Task 1) |
| `constants/general.js` | ✅ `EXPRESS_CHECKOUT` constants added |
| `releases/ApplePayExpress/meta/...` | ✅ `ApplePayExpress_Enabled`, `ApplePayExpress_Pdp_Enabled`, `ApplePayExpress_Configs` site preferences defined |
| `payment.properties` | ✅ Apple Pay resource strings added |

---

## File Map (remaining work)

| Action | File | Purpose |
|--------|------|---------|
| **Modify** | `app_baccarat/cartridge/adyen/utils/adyenConfigs.js` | Fix: remove duplicate function + export `isApplePayExpressOnPdpEnabled` |
| **Modify** | `app_baccarat/cartridge/templates/default/product/components/applePayExpressButton.isml` | Fix: replace PayPal container div with Apple Pay `.applepay` div |
| **Modify** | `app_baccarat/cartridge/client/default/js/applePayExpress.js` | Add `hasChildNodes()` mount guard (defensive) |
| **Build** | `app_baccarat/cartridge/static/default/js/applePayExpress.js` | Rebuild webpack output |

---

## Task 1: Fix `adyenConfigs.js` — duplicate function + missing export

**Files:**
- Modify: `app_baccarat/cartridge/adyen/utils/adyenConfigs.js`

**Background:** Two bugs were introduced on the branch:
1. There are two functions named `isApplePayExpressEnabled` in the file. The first (around line 100) is a simplified version with a TODO comment and simpler logic (doesn't use `ApplePayExpress_Configs`). The second (around line 130) is the full production implementation. In Rhino (SFCC's JS engine), the second definition wins — but the dead first function is confusing and must be removed.
2. `isApplePayExpressOnPdpEnabled` is defined but never added to the `base` exports. `buttonsBlockPDP.isml` calls `AdyenConfigs.isApplePayExpressOnPdpEnabled()` at render time — this throws a runtime error.

- [ ] **Step 1: Read the current file**

```
app_baccarat/cartridge/adyen/utils/adyenConfigs.js
```

Locate the two `isApplePayExpressEnabled` functions and the exports block at the bottom.

- [ ] **Step 2: Remove the first (incomplete) `isApplePayExpressEnabled` function**

The function to delete starts with the comment `// TODO: Update for Apple Pay config and check if it's iOS` and ends just before the JSDoc block of the second implementation. It looks like:

```javascript
// TODO: Update for Apple Pay config and check if it's iOS
function isApplePayExpressEnabled(page, product, basketProducts) {
    const ApplePayExpress_Enabled = Site.current.getCustomPreferenceValue("ApplePayExpress_Enabled");

    if (!ApplePayExpress_Enabled) return false;

    try {
        if (!page && !product && !basketProducts) {
            return ApplePayExpress_Enabled;
        } else if (!isProductsEligible(product, basketProducts)) {
            return false;
        }
    } catch (e) {
        Logger.error("[{0}] - [{1}] - {2} - at line {3}", e.fileName, e.name, e.message, e.lineNumber);
        return false;
    }

    return ApplePayExpress_Enabled;
}
```

Delete it entirely. The second `isApplePayExpressEnabled` (with the JSDoc comment starting with `* Determines if Apple Pay Express is enabled for the current context`) is the one to keep.

- [ ] **Step 3: Add `isApplePayExpressOnPdpEnabled` to the exports block**

Find the exports block at the bottom of the file:

```javascript
base.getAdyenAccountConfig = getAdyenAccountConfig;
base.getAdyenConfigByCountry = getAdyenConfigByCountry;
base.isPayPalExpressEnabled = isPayPalExpressEnabled;
base.isApplePayExpressEnabled = isApplePayExpressEnabled;

module.exports = base;
```

Add the missing line:

```javascript
base.getAdyenAccountConfig = getAdyenAccountConfig;
base.getAdyenConfigByCountry = getAdyenConfigByCountry;
base.isPayPalExpressEnabled = isPayPalExpressEnabled;
base.isApplePayExpressEnabled = isApplePayExpressEnabled;
base.isApplePayExpressOnPdpEnabled = isApplePayExpressOnPdpEnabled;

module.exports = base;
```

- [ ] **Step 4: Verify only one `isApplePayExpressEnabled` remains**

```bash
grep -c "^function isApplePayExpressEnabled" cartridges/app_baccarat/cartridge/adyen/utils/adyenConfigs.js
```

Expected: `1`

- [ ] **Step 5: Verify `isApplePayExpressOnPdpEnabled` is exported**

```bash
grep "isApplePayExpressOnPdpEnabled" cartridges/app_baccarat/cartridge/adyen/utils/adyenConfigs.js
```

Expected: three lines — function definition, the `if` guard inside it (calling `base.isApplePayExpressOnPdpEnabled()`), and the export line.

- [ ] **Step 6: Commit**

```bash
git add cartridges/app_baccarat/cartridge/adyen/utils/adyenConfigs.js
git commit -m "fix(apple-pay): remove duplicate isApplePayExpressEnabled and export isApplePayExpressOnPdpEnabled"
```

---

## Task 2: Fix `applePayExpressButton.isml` — wrong container div

**Files:**
- Modify: `app_baccarat/cartridge/templates/default/product/components/applePayExpressButton.isml`

**Background:** This template renders inside the Apple Pay optin modal and is loaded via `Cart-ApplePayExpressOptinPopin`. It sets all `window.*` vars and then provides the mount container for the Adyen Apple Pay component. The branch left a TODO: the container div still says `data-method="paypal"` and `id="paypal-container"` — copied from the PayPal template and never updated.

`applePayExpress.js` mounts the button by calling `document.getElementsByClassName(APPLE_PAY)` where `APPLE_PAY = "applepay"`. The container div must have class `applepay`.

- [ ] **Step 1: Read the current file**

```
app_baccarat/cartridge/templates/default/product/components/applePayExpressButton.isml
```

At the bottom you will see:

```isml
<div id="express-container" class="hidden">
<iscomment>
    TODO: Update Apple Pay button
</iscomment>
    <div data-method="paypal" class="expressComponent" id="paypal-container" style="padding:0"></div>
</div>
```

- [ ] **Step 2: Replace the TODO block with the correct Apple Pay container**

Replace the block above with:

```isml
<div id="express-container" class="hidden">
    <div data-method="applepay" class="applepay expressComponent" id="applepay-container"></div>
</div>
```

Remove the `<iscomment>TODO...</iscomment>` as well.

- [ ] **Step 3: Verify the `window.isApplePayExpressEnabled` var is set correctly**

In the same file, confirm the script block includes:

```isml
window.isApplePayExpressEnabled = "${pdict.AdyenConfigs.isApplePayExpressEnabled()}";
```

This call has no args — the function checks `ApplePayExpress_Configs` and returns a truthy value when enabled site-wide. `expressPayments.js` checks `window.isApplePayExpressEnabled === 'true'`, so this must output `"true"`.

The `isApplePayExpressEnabled()` function with no args returns `applePayConfigs && applePayConfigs.enabled`. If the JSON config's `enabled` is the boolean `true`, this will serialize to `"true"` in ISML. Confirm this is correct once the site preference is configured.

- [ ] **Step 4: Commit**

```bash
git add cartridges/app_baccarat/cartridge/templates/default/product/components/applePayExpressButton.isml
git commit -m "fix(apple-pay): replace PayPal container with Apple Pay mount div in express button template"
```

---

## Task 3: Add mount guard to `applePayExpress.js`

**Files:**
- Modify: `app_baccarat/cartridge/client/default/js/applePayExpress.js`

**Background:** The `expressOptinPopin.js` handler removes and re-injects `expressPayments.js` each time the modal opens (after removing the old modal from the DOM). This means `applePayExpress.js` `init()` can run again while a `.applepay` div from a previous modal session might still exist in the DOM briefly. Adding a `hasChildNodes()` guard is defensive but low-risk.

Note: this file is the **source** file. The built version lives at `cartridge/static/default/js/applePayExpress.js`. The source is compiled by webpack. After editing the source, run the build (Task 4).

- [ ] **Step 1: Locate the mount loop in the source file**

```
app_baccarat/cartridge/client/default/js/applePayExpress.js
```

Search for the mount loop (around line 519 in the source):

```javascript
if (isApplePayButtonAvailable) {
    for (expressCheckoutNodesIndex = 0; expressCheckoutNodesIndex < cartContainer.length; expressCheckoutNodesIndex += 1) {
        applePayButton.mount(cartContainer[expressCheckoutNodesIndex]);
    }
}
```

- [ ] **Step 2: Add the `hasChildNodes()` guard**

Replace with:

```javascript
if (isApplePayButtonAvailable) {
    for (expressCheckoutNodesIndex = 0; expressCheckoutNodesIndex < cartContainer.length; expressCheckoutNodesIndex += 1) {
        if (!cartContainer[expressCheckoutNodesIndex].hasChildNodes()) {
            applePayButton.mount(cartContainer[expressCheckoutNodesIndex]);
        }
    }
}
```

The `hasChildNodes()` check is sufficient: the Adyen SDK populates the div immediately on `mount()`, so a non-empty container means the button is already rendered. Do not change `updateLoadedExpressMethods` or `checkIfExpressMethodsAreReady` — they must still run after the loop.

- [ ] **Step 3: Commit the source change**

```bash
git add cartridges/app_baccarat/cartridge/client/default/js/applePayExpress.js
git commit -m "fix(apple-pay): skip mount if container already populated"
```

---

## Task 4: Build static assets

- [ ] **Step 1: Install dependencies (if needed)**

```bash
npm install
```

Expected: `added N packages` or `up to date, audited N packages`

- [ ] **Step 2: Run the development build**

```bash
npm run ci
```

Expected: webpack completes with no errors. Watch for `app_baccarat/...applePayExpress.js` in the output.

- [ ] **Step 3: Verify the built static file contains the mount guard**

```bash
grep -c "hasChildNodes" cartridges/app_baccarat/cartridge/static/default/js/applePayExpress.js
```

Expected: `1` (the guard appears once in the compiled output).

- [ ] **Step 4: Commit the static asset**

```bash
git add cartridges/app_baccarat/cartridge/static/default/js/applePayExpress.js
git add cartridges/app_baccarat/cartridge/static/default/js/applePayExpress.js.map
git commit -m "build: rebuild applePayExpress.js with mount guard"
```

---

## Task 5: Deploy and smoke test

- [ ] **Step 1: Deploy cartridges to sandbox**

Use your standard b2c-code deploy command for `app_baccarat`.

- [ ] **Step 2: Configure `ApplePayExpress_Configs` site preference**

In Business Manager → Merchant Tools → Site Preferences → Custom Preferences → Adyen, set `ApplePayExpress_Configs` to a JSON object matching the PayPal config structure. Example for NORA:

```json
{
  "US": {
    "enabled": true,
    "pages": {
      "cart": true,
      "pdp": true
    },
    "devices": {
      "mobile": true,
      "desktop": true
    }
  },
  "default": {
    "enabled": false
  }
}
```

Also set `ApplePayExpress_Enabled = true` and `ApplePayExpress_Pdp_Enabled = true`.

> ⚠️ **Domain registration required.** Apple Pay will not render unless the domain is registered with Apple through Adyen BM (Account → Apple Pay → Domain Registration). Sandbox `*.demandware.net` domains are typically pre-registered; production domains need explicit registration before go-live.

- [ ] **Step 3: Cart smoke test (Safari on iPhone or Mac with Touch ID/Face ID)**

1. Add a normal in-stock product to cart
2. Navigate to cart page
3. Verify: Apple Pay trigger button appears (Apple Pay icon button)
4. Click the trigger → modal opens with terms/privacy checkboxes
5. Check both checkboxes → Apple Pay button becomes active
6. Click Apple Pay button → Apple Pay payment sheet opens
7. Select shipping address → verify shipping methods appear and total updates
8. Select shipping method → verify total updates
9. Authorize with Touch ID / Face ID
10. Verify: redirect to order confirmation page

- [ ] **Step 4: Cart negative tests**

| Scenario | Expected result |
|---|---|
| Cart with a preorder product | Apple Pay trigger button not shown |
| Cart with a private sales product | Apple Pay trigger button not shown |
| Non-Apple device / Chrome | Trigger button hidden by `expressPaymentMethodsVisibility.js` |
| Click "Buy with PayPal" | PayPal modal opens; Apple Pay trigger unchanged |

- [ ] **Step 5: PDP Revamp smoke test**

1. Navigate to a standard in-stock product PDP (Revamp template)
2. Verify: Apple Pay trigger button appears below the add-to-cart button
3. Click trigger → terms modal opens
4. Accept terms → Apple Pay button activates
5. Authorize → order confirmation

- [ ] **Step 6: PDP negative tests**

| Scenario | Expected result |
|---|---|
| Out-of-stock product PDP | Apple Pay trigger not shown (`isApplePayExpressOnPdpEnabled` gate in `buttonsBlockPDP.isml`) |
| Preorder product PDP | Apple Pay trigger not shown |
| Set product PDP | Apple Pay trigger not shown (set excluded in `isProductsEligible`) |

---

## Scope not covered by this plan

- **Non-revamp PDP** (`addToCartButtonPDP.isml`) — no Apple Pay trigger added there; follow-up if the non-revamp PDP is still in use on any site
- **Mini-cart Apple Pay** — `miniCart.isml` shows the PayPal optin trigger; Apple Pay trigger there is a follow-up
- **Google Pay Express PDP via optin popin** — would follow the same pattern
- **Production domain registration** — must be done by the client in Adyen BM before each production go-live

# GitHub Copilot Instructions — Apple Pay Express remaining fixes

**Branch:** `feature/BCRTR-1611`
**Repo root:** `cartridges/app_baccarat/`

The Apple Pay Express optin-popin flow is mostly implemented on this branch. Three bugs remain. Apply each fix below exactly as described — do not refactor surrounding code.

---

## Fix 1: `adyenConfigs.js` — remove duplicate function + add missing export

**File:** `cartridges/app_baccarat/cartridge/adyen/utils/adyenConfigs.js`

### 1a — Remove the first (incomplete) `isApplePayExpressEnabled` function

There are two functions named `isApplePayExpressEnabled` in this file. Find and delete the FIRST one — it is preceded by the comment `// TODO: Update for Apple Pay config and check if it's iOS` and uses simpler logic that does not reference `ApplePayExpress_Configs`. Delete from the `// TODO` comment through the closing `}` of that function.

The function to DELETE looks like this (exact text):

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

Keep the second `isApplePayExpressEnabled` — the one with the JSDoc comment starting `* Determines if Apple Pay Express is enabled for the current context`.

### 1b — Export `isApplePayExpressOnPdpEnabled`

Find the exports block at the bottom of the file. It currently ends with:

```javascript
base.isApplePayExpressEnabled = isApplePayExpressEnabled;

module.exports = base;
```

Add one line so it becomes:

```javascript
base.isApplePayExpressEnabled = isApplePayExpressEnabled;
base.isApplePayExpressOnPdpEnabled = isApplePayExpressOnPdpEnabled;

module.exports = base;
```

**Verify:** After your edits, `grep -c "^function isApplePayExpressEnabled"` on this file should return `1`.

---

## Fix 2: `applePayExpressButton.isml` — wrong container div

**File:** `cartridges/app_baccarat/cartridge/templates/default/product/components/applePayExpressButton.isml`

At the bottom of this file, replace this block:

```isml
<div id="express-container" class="hidden">
<iscomment>
    TODO: Update Apple Pay button
</iscomment>
    <div data-method="paypal" class="expressComponent" id="paypal-container" style="padding:0"></div>
</div>
```

With:

```isml
<div id="express-container" class="hidden">
    <div data-method="applepay" class="applepay expressComponent" id="applepay-container"></div>
</div>
```

**Why:** `applePayExpress.js` mounts the Adyen Apple Pay component by calling `document.getElementsByClassName("applepay")`. The div must have class `applepay` and `data-method="applepay"`. The old content was copied from the PayPal template and never updated.

Do not change anything else in this file.

---

## Fix 3: `applePayExpress.js` — add mount guard

**File:** `cartridges/app_baccarat/cartridge/client/default/js/applePayExpress.js`

Find the mount loop. It looks like this:

```javascript
if (isApplePayButtonAvailable) {
    for (expressCheckoutNodesIndex = 0; expressCheckoutNodesIndex < cartContainer.length; expressCheckoutNodesIndex += 1) {
        applePayButton.mount(cartContainer[expressCheckoutNodesIndex]);
    }
}
```

Replace the loop body with a guard that skips containers that are already populated:

```javascript
if (isApplePayButtonAvailable) {
    for (expressCheckoutNodesIndex = 0; expressCheckoutNodesIndex < cartContainer.length; expressCheckoutNodesIndex += 1) {
        if (!cartContainer[expressCheckoutNodesIndex].hasChildNodes()) {
            applePayButton.mount(cartContainer[expressCheckoutNodesIndex]);
        }
    }
}
```

**Why:** When the express optin modal is opened, `expressOptinPopin.js` removes and re-injects `expressPayments.js`. If a `.applepay` div from a previous session is still in the DOM, calling `mount()` a second time throws an error. `hasChildNodes()` detects the already-mounted button and skips it.

Do not change `updateLoadedExpressMethods` or `checkIfExpressMethodsAreReady` — those must still run after the loop.

---

## After applying fixes: build and verify

Run the webpack build to compile the source JS change (Fix 3) into the static file:

```bash
npm run ci
```

Then verify:

```bash
# Should return 1
grep -c "hasChildNodes" cartridges/app_baccarat/cartridge/static/default/js/applePayExpress.js

# Should return 1
grep -c "^function isApplePayExpressEnabled" cartridges/app_baccarat/cartridge/adyen/utils/adyenConfigs.js

# Should contain "applepay" class
grep "applepay" cartridges/app_baccarat/cartridge/templates/default/product/components/applePayExpressButton.isml
```

---

## Context: what NOT to change

These files were already correctly updated on this branch — do not touch them:

- `expressOptinPopin.js` — unified optin popin handler (replaces `payPalExpressOptinPopin.js`)
- `applePayExpressOptinPopin.isml` — modal structure
- `applePayExpressOptinPopinTrigger.isml` — trigger button
- `cart.isml` — Apple Pay trigger buttons added (mobile + desktop)
- `buttonsBlockPDP.isml` — Apple Pay trigger on PDP
- `Cart.js` — `Cart-ApplePayExpressOptinPopin` route
- `constants/general.js` — `EXPRESS_CHECKOUT` constants
- `payment.properties` — Apple Pay resource strings

---

## Site Preference configuration (after deploy)

In Business Manager → Site Preferences → Adyen, set:

| Preference | Value |
|---|---|
| `ApplePayExpress_Enabled` | `true` |
| `ApplePayExpress_Pdp_Enabled` | `true` |
| `ApplePayExpress_Configs` | JSON — see example below |

`ApplePayExpress_Configs` example (same structure as `PayPalExpress_Configs`):

```json
{
  "US": {
    "enabled": true,
    "pages": { "cart": true, "pdp": true },
    "devices": { "mobile": true, "desktop": true }
  },
  "default": { "enabled": false }
}
```

The key names must match the country codes returned by `localeHelpers.getCurrentCountry().countryCode`.

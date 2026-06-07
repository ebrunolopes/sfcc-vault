---
type: analysis
client: MyO
slug: breadcrumblist-structured-data
date: 2026-05-22
status: draft
sfcc-version: 24.6
sfra-version: 7.1
related-tickets: []
related-tsds: []
related-adrs: []
tags: ["#sfra/isml", "#integration", "#draft"]
---

# Analysis — BreadcrumbList JSON-LD Re-implementation After Botify Shutdown

> Architect-level analysis. Not a TSD. Promote to TSD only after review.
> Inputs: BreadcrumbList Structured Data Re-implementation ticket (no Jira key provided).

## 1. Requirement Summary

Since March 31 the site has no BreadcrumbList structured data. It was being injected at the CDN edge by Botify Page Workers (CSS-selector-based), which is now off-contract. The objective is to regenerate the same `BreadcrumbList` JSON-LD server-side, inside the SFCC storefront, so that Googlebot reads it on the initial HTML response without any client-side rendering dependency.

Concrete acceptance criteria:

- JSON-LD `BreadcrumbList` block is present in the page HTML on first load, no JavaScript required.
- Covers all page types that currently render a breadcrumb: category pages (PLP), product detail pages (PDP), CMS/content pages, and search results pages (if a breadcrumb is shown there).
- Format matches the expected schema: `@context`, `@type: BreadcrumbList`, `itemListElement[]` with `@type: ListItem`, `position`, `name`, `item` (absolute URL).
- Passes Google Rich Results Test without errors.
- Last breadcrumb item (current page) is included with its absolute URL as `item`.

## 2. Technical Feasibility

**Can SFCC do this?** Yes — fully supported in SFRA. Breadcrumb data is built server-side on every applicable request.

**Where in the platform does this live?**

The breadcrumb sub-system in this codebase is a custom mini-framework in `app_sfra_light`:

- **`BreadcrumbFactory`** (`app_sfra_light/cartridge/scripts/factories/BreadcrumbFactory.js`) — factory that dispatches to typed models (PRODUCT, CATEGORY, HOME, PAGE, CUSTOM, ACCOUNT).
- **`BreadcrumbModel` hierarchy** — `BreadcrumbModel` (base) → `HomeBreadcrumbModel` → `CategoryBreadcrumbModel` / `ProductBreadcrumbModel` / `CustomBreadcrumbModel` / `AccountBreadcrumbModel`. Each model builds an `items[]` array via `addItem(name, url, sourceObject)`.
- **`BreadcrumbMiddleware.show`** (`app_sfra_light/.../middleware/BreadcrumbMiddleware.js`) — a controller action (`Breadcrumb-Show`) that calls `BreadcrumbFactory.create()` and renders `components/breadcrumb` with `pdict.breadcrumb` set to the model instance.
- **`components/breadcrumb.isml`** (`mo_storefront`) — renders the visible breadcrumb HTML using `pdict.breadcrumb.getItems()`, iterating items with `{name, url}` properties.

**Critical architectural constraint:** `Breadcrumb-Show` is called via `<isinclude url="...">` from within page body templates. It executes as a separate sub-request with its own isolated pdict. The parent page's `htmlHead.isml` renders before any body remote includes, so `pdict.breadcrumb` is **not available** in `htmlHead.isml`. This rules out a simple "check pdict in head" approach.

**URL format in BreadcrumbModel items:** `CategoryBreadcrumbModel` stores `URLUtils.url('Search-Show', 'cgid', ...)` — a `dw.web.URL` object that resolves to a **relative path** (e.g. `/on/demandware.store/Sites-.../Search-Show?cgid=maquillage` or the rewritten friendly URL). JSON-LD `item` requires an **absolute URL**. Absolutization must be handled explicitly.

**What's already there:**
- `mo_storefront/components/seo/` directory with SEO components (title, description, otherMeta, alternateurls) included via `components/seo/index` from `htmlHead.isml`. This is the natural injection point if head placement is chosen.
- `components/breadcrumb.isml` is already overridden in `mo_storefront` — safe to extend.
- No existing JSON-LD structured data in the codebase.

**Cartridge boundary:** All changes go in `mo_storefront`. `app_sfra_light` is shared infrastructure — avoid modifying it unless adding a method to `BreadcrumbModel` that is clearly generic and reusable. A decorator in `mo_core` or direct extension in `mo_storefront` is preferred.

## 3. Architecture Options

### Option A — JSON-LD block appended inside `breadcrumb.isml` (body placement)

**Shape.** Extend the existing `mo_storefront/components/breadcrumb.isml` to emit a `<script type="application/ld+json">` block alongside the visible breadcrumb HTML. All data is already present in `pdict.breadcrumb.getItems()`. An `<isscript>` block builds the JSON string server-side with proper escaping and absolute URL construction; the JSON is output after the visible breadcrumb HTML.

**Files / touchpoints:**
- `cartridges/mo_storefront/cartridge/templates/default/components/breadcrumb.isml` — extend (add `<isscript>` + `<script type="application/ld+json">` block)
- No controller changes, no new files.

**Effort.** S — ~0.5–1 day including URL handling and testing.

**Pros.**
- Zero controller changes; zero new files.
- Automatically covers every page type that already calls `Breadcrumb-Show` — no enumeration required.
- Google explicitly supports JSON-LD in `<body>` — this is not a hack.
- Encoding handled in server-side `<isscript>` context with full access to `JSON.stringify()` and string replacement.
- Single place to maintain.

**Cons.**
- JSON-LD ends up in the body, not `<head>`. Contradicts the ticket's stated placement preference (though not a Google requirement).
- Slightly mixes concerns: one template handles both presentation and structured data output.

**Best when.** This is the right choice — always. The "inject in head" wording in the ticket reflects Botify's CDN approach, not a Google requirement. Body placement is supported and tested.

---

### Option B — Override main controllers + head injection via SEO components

**Shape.** Override `Search-Show`, `Product-Show`, and any content/CMS controller in `mo_storefront` to additionally call `BreadcrumbFactory.create()` with the appropriate type/oid, build the JSON-LD string server-side, and set it in `res.setViewData({ breadcrumbJsonLd: '...' })`. Add a new `components/seo/structuredData.isml` that checks `pdict.breadcrumbJsonLd` and emits the script tag. Wire into `components/seo/index.isml`.

**Files / touchpoints:**
- `cartridges/mo_storefront/cartridge/controllers/Search.js` — override `Show` action to add breadcrumb JSON-LD to viewData
- `cartridges/mo_storefront/cartridge/controllers/Product.js` — override `Show` action similarly
- `cartridges/mo_storefront/cartridge/controllers/Page.js` — override `Show` for CMS pages (if breadcrumbs apply)
- `cartridges/mo_storefront/cartridge/templates/default/components/seo/structuredData.isml` — new
- `cartridges/mo_storefront/cartridge/templates/default/components/seo/index.isml` — add one include line
- No system object or site pref changes.

**Effort.** M — ~2 days: 3+ controller overrides, one new template, integration testing per page type.

**Pros.**
- JSON-LD lives in `<head>`, matching the ticket's stated preference and common SEO practice.
- Clean separation: structured data is a SEO component concern.
- `components/seo/` pattern is already established in the codebase.

**Cons.**
- Each controller override duplicates the BreadcrumbFactory call — the breadcrumb is now built twice per request on applicable pages (once for JSON-LD in the controller, once for the visible breadcrumb in the sub-request).
- Miss any controller (e.g. a custom CMS or account page) and those pages silently lack the structured data.
- More files, more tests, more upgrade surface.

**Best when.** The team has a firm policy that structured data must be in `<head>`, or if Google Search Console flags the body placement (unlikely but possible for edge cases with CSP headers).

---

### Option C — `request.custom` bridge between sub-request and parent

**Shape.** Override `BreadcrumbMiddleware.show` in `mo_storefront` to also write the JSON-LD string to `request.custom.breadcrumbJsonLd`. Then add a new template (`components/seo/breadcrumbJsonLd.isml`) that reads `request.custom.breadcrumbJsonLd` and outputs the script tag. Include this template from each page body template AFTER the breadcrumb include (where `request.custom` is already populated). Still body placement, but controlled to appear near the breadcrumb.

**Files / touchpoints:**
- `cartridges/mo_storefront/cartridge/controllers/Breadcrumb.js` — new (override `BreadcrumbMiddleware.show`)
- `cartridges/mo_storefront/cartridge/templates/default/components/seo/breadcrumbJsonLd.isml` — new
- Page body templates (category, PDP, content) — add one `<isinclude>` per template

**Effort.** S-M — ~1 day. Moderate risk of ordering bugs.

**Pros.**
- Single override point for the JSON-LD building (BreadcrumbMiddleware only).
- `request.custom` is legitimate for sharing data within the same request.

**Cons.**
- Fragile: relies on the breadcrumb remote include completing before the consuming template renders. This is true today but could silently break if template composition changes.
- Still body placement.
- Harder to test (requires simulating sub-request + parent request chain).
- More moving parts than Option A for the same end result.

**Best when.** Never — Option A is simpler with the same outcome; Option B is cleaner if head placement is required.

---

### Recommendation

**Ship Option A.**

The "inject in head" wording in the ticket is inherited from how Botify's edge module worked, not from a Google requirement. Google's structured data documentation explicitly states JSON-LD can appear in `<head>` or `<body>`. Option A requires one file change, reuses data already built by the existing sub-request, handles encoding safely in `<isscript>`, and covers every page type automatically. Option B costs double the effort for a placement distinction that has no SEO value.

**If close call:** If the team later decides head placement is a firm requirement (e.g. for CSP or tooling reasons), promote to Option B. But don't do it speculatively.

## 4. Risk & Impact

### Performance

No performance risk. `BreadcrumbMiddleware.show` already runs a `CatalogMgr.getCategory()` or `ProductMgr.getProduct()` call for the breadcrumb. The JSON-LD block adds only string operations in `<isscript>` — negligible. No additional API calls, no cache implications. The `components/breadcrumb` sub-request is already happening; we are just adding a few lines to its response.

### Security (OWASP frame)

**XSS risk — JSON injection in `<script>` tag.** This is the main risk. ISML's default `${expression}` uses HTML encoding, which is **wrong** inside a `<script type="application/ld+json">` block — the browser parses the content as JSON, not HTML, so `&amp;` would appear literally instead of `&`.

Mitigation: build the JSON string inside `<isscript>` using `JSON.stringify()`, then manually replace `</script>` with `<\/script>` in the output string. Output the result with `<isprint value="${jsonStr}" encoding="off" />`. The `encoding="off"` is safe here because `JSON.stringify()` handles all necessary escaping, and the `</script>` replacement closes the injection vector.

```javascript
// inside <isscript>
var items = pdict.breadcrumb.getItems();
var ldItems = [];
for (var i = 0; i < items.length; i++) {
    ldItems.push({
        '@type': 'ListItem',
        position: i + 1,
        name: items[i].name,
        item: absoluteUrl(items[i].url)  // see open question #1
    });
}
var jsonStr = JSON.stringify({
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: ldItems
}).replace(/<\/script>/gi, '<\\/script>');
```

No CSRF concern (read-only template output). No PII in breadcrumb data (category names, product names, page names). No AuthN/AuthZ surface.

### Accessibility (WCAG 2.1 AA)

`<script type="application/ld+json">` is invisible to AT. No impact on keyboard navigation, ARIA, or contrast. No accessibility risk.

### Integration / cartridge boundaries

- `plugin_sitemap` is in the cartridge path and is SEO-adjacent, but handles sitemaps not structured data — no conflict.
- `int_gtm` (GTM integration) is upstream of `mo_storefront` — no conflict; this is server-rendered HTML, not a dataLayer push.
- `int_bazaarvoice` and `bm_bazaarvoice` may inject their own structured data (Product reviews). No known conflict with BreadcrumbList, but worth verifying there are no duplicate `<script type="application/ld+json">` blocks of the same type.
- Upgrade safety: `breadcrumb.isml` is already overridden in `mo_storefront`. Changes live entirely in the overlay — no risk from SFRA or `app_sfra_light` updates.

### Observability

No new log categories needed. If the JSON-LD block is unexpectedly empty or malformed, the Google Rich Results Test will surface it. Consider adding a log line at `DEBUG` level in the `<isscript>` block (breadcrumb items count) during development — remove before go-live.

### Testing strategy

**Unit:** Mock `BreadcrumbModel.getItems()` with various inputs (0 items, 1 item, items with special characters like `"`, `<`, `/`). Assert the JSON string is valid JSON and that `</script>` sequences are neutralized.

**Integration (manual + Rich Results Test):**
1. Category page (PLP) — verify BreadcrumbList JSON-LD present, positions correct, URLs absolute.
2. PDP — verify product and category ancestors appear in correct order.
3. CMS/content page — verify presence or graceful absence (template only emits the block if `pdict.breadcrumb` is non-null and `getItems()` is non-empty).
4. Search results page (keyword search, no `cgid`) — verify no JSON-LD emitted if no breadcrumb is shown.
5. Home page — verify either absent or emits just the home item.
6. Run Google Rich Results Test on at least one URL from each page type.
7. Validate JSON output is valid JSON (copy-paste into JSONLint).

**Hard to unit-test:** URL absolutization logic that depends on the live request host — cover with integration/manual test.

### Deprecation / debt

The Botify Page Workers module is already gone. There is no legacy code to retire in the SFCC codebase — the structured data was never in the codebase to begin with. No deprecation work.

## 5. Open Questions for Stakeholders

- [ ] **URL absolutization:** `URLUtils.url()` in `CategoryBreadcrumbModel` returns a relative `dw.web.URL` object. The safest way to get an absolute URL server-side is `'https://' + request.httpHost + item.url.toString()`. Confirm that `request.httpHost` reliably returns the storefront hostname (not internal proxy hostnames) in the SFCC hosting environment for both FR and other locales.
- [ ] **Last breadcrumb item URL:** In the visible breadcrumb template, the last item (current page) renders without an `<a>` tag. Does `BreadcrumbModel.addItem()` receive a populated `url` for the last item, or is it null/empty? If empty, the `item` property in JSON-LD for the last ListItem should fall back to the canonical URL (`pdict.canonicalUrl` if exposed, or `request.httpURL`). Needs a runtime check across all breadcrumb types (PRODUCT, CATEGORY, PAGE).
- [ ] **CMS/content pages:** Does `Page-Show` (or the equivalent content controller in `mo_storefront`) call `Breadcrumb-Show`? If not, CMS pages will have no JSON-LD after this implementation. Confirm scope expectation with stakeholders.
- [ ] **Multi-locale/multi-site:** The `item` URL in JSON-LD must be locale-specific (e.g. `https://www.my-origines.com/fr/maquillage` not `/en/maquillage`). Confirm `request.httpHost` + `item.url.toString()` correctly includes the locale prefix across all active sites.

## 6. Contradictions / Red Flags

The ticket states "to be injected in the `<head>`" but the SFCC architecture (remote include sub-request for breadcrumb) makes head injection non-trivial without touching controllers. This is not a contradiction in the requirements themselves, but it is a mismatch between the stated implementation approach and the actual SFCC rendering pipeline. The body placement recommendation resolves this without sacrificing any SEO value.

The ticket also lists "search results pages" as a target. A keyword search results page (no `cgid`) typically shows no breadcrumb in SFRA. If `Breadcrumb-Show` is not called for keyword search, there will be no JSON-LD there — which is correct behavior (no breadcrumb to represent). Worth confirming whether keyword search pages show a breadcrumb on this storefront.

## 7. Effort & Sequencing

- **Total effort estimate:** S — 1 day end-to-end (half day implementation, half day testing across page types).
- **Suggested sequence:**
  1. Resolve open questions 1 and 2 (URL absolutization strategy, last-item URL) — 1 hour.
  2. Implement `<isscript>` + JSON-LD output in `breadcrumb.isml` with URL absolutization and `</script>` escaping — 2 hours.
  3. Local/sandbox smoke test: inspect HTML source on PLP, PDP, home — 1 hour.
  4. Run Google Rich Results Test on 2–3 live or staging URLs — 30 min.
  5. Review and merge.
- **Prerequisites:** Staging/sandbox environment accessible for manual testing and Rich Results Test validation. Answer to open question #1 (URL absolutization) before writing code.

## 8. Source Material

- Tickets: No Jira key provided — ticket title: "BreadcrumbList Structured Data Re-implementation Following Botify Page Workers Module Shutdown"
- Pasted at: 2026-05-22
- Notes on input quality: Requirement is well-specified. Technical information from Botify (CSS selectors, JSON-LD format) is accurate and matches the current ISML structure (`div.mo-breadcrumb > ul[role="navigation"] > li > a`). Missing: Jira key, scope confirmation for CMS pages and keyword search pages.

## 9. Next Steps

1. Answer open questions in section 5 — particularly URL absolutization and CMS page scope — before writing code.
2. If recommendation accepted → implement Option A, then promote this analysis to a TSD at `~/work/SFCC-Vault/10-Clients/MyO/TSDs/TSD-2026-05-22-breadcrumblist-structured-data.md`.
3. ADR-worthy decisions: **body vs. head placement for JSON-LD** — if the team has a policy either way, record it as an ADR so future structured data work (Product, Organization, FAQPage) follows the same pattern.
4. After implementation, monitor Google Search Console for rich result impressions recovery (2–4 week lag expected after deployment).

---
type: client-overview
client: MyOrigines
status: active
sfcc-version: "26.5"
sfra-version: <e.g. 7.1>
sites:
  - MyOrigines_HUB
  - MyOrigines_FR 
  - MyOrigines_ROE 
  - MyOrigines_UK
realms: []
tags:
  - meta
---

# MyOrigines — Overview

## Stack snapshot

- **SFCC version:** 
- **SFRA version:** 
- **PWA Kit / headless?** no
- **Realms:** 
- **Sites:** 
- **Locales:** 
- **Currencies:** 

## Cartridge path

> Document the canonical cartridge path order for each site. Order matters — it's the overlay precedence.

**Site: `MyOrigines_HUB`**
```
mo_core_zones:mo_storefront:mo_core:int_gtm:int_citrusAd:int_epsilon_sfra:app_sfra_light:form:int_mailchimp:int_hipay:int_shop2shop:int_mondialrelay:plugin_sitemap
```

**Site: `MyOrigines_FR`**
```
int_apple_signin:int_bazaarvoice:mo_storefront:mo_core:int_gtm:int_citrusAd:int_epsilon_sfra:app_sfra_light:form:int_mailchimp:int_shop2shop:int_mondialrelay:plugin_sitemap:int_hipay_sfra:int_hipay_core:plugin_jwt:app_storefront_base:bm_bazaarvoice
```

**Site: `MyOrigines_ROE`**
```
int_apple_signin:int_bazaarvoice:mo_storefront:mo_core:int_gtm:int_citrusAd:int_epsilon_sfra:app_sfra_light:form:int_mailchimp:int_shop2shop:int_mondialrelay:plugin_sitemap:int_hipay_sfra:int_hipay_core:plugin_jwt:app_storefront_base:bm_bazaarvoice
```

**Site: `MyOrigines_UK`**
```
int_apple_signin:int_bazaarvoice:mo_storefront:mo_core:int_gtm:int_citrusAd:int_epsilon_sfra:app_sfra_light:form:int_mailchimp:int_shop2shop:int_mondialrelay:plugin_sitemap:int_hipay_sfra:int_hipay_core:plugin_jwt:app_storefront_base:bm_bazaarvoice
```


## Business Manager access

- BM URL: 
- SSO / IdP: 
- Roles I have:

## Key integrations

> Link to one note per integration in `Integrations/`.

- [[Integrations/oms-<vendor>]]
- [[Integrations/pim-<vendor>]]
- [[Integrations/payment-<vendor>]]
- [[Integrations/auth-<vendor>]]

## Deployment

- **VCS:** GitHub / Bitbucket / GitLab
- **CI/CD:** 
- **Code versions strategy:** 
- **Sandbox setup:** 

## Active work

```dataview
TABLE WITHOUT ID file.link AS Note, type, status, date
FROM "10-Clients/MyOrigines"
WHERE (type = "tsd" OR type = "plan") AND status != "archived"
SORT date DESC
```

## Recent incidents

```dataview
TABLE summary, severity, date
FROM "10-Clients/MyOrigines"
WHERE type = "incident"
SORT date DESC
LIMIT 10
```

## Recent reviews

```dataview
TABLE pr, file.link AS Review, status, severity, date
FROM "10-Clients/MyOrigines"
WHERE type = "review"
SORT date DESC
LIMIT 10
```

## Notes / gotchas

> Tribal knowledge that doesn't fit anywhere else. Things future-you would have wanted to know.

- 

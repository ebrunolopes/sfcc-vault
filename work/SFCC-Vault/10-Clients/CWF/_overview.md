---
type: client-overview
client: CWF
status: active
sfcc-version: "26.5"
sfra-version: <e.g. 7.1>
sites:
  - CWF-EMEA
  - CWF-US
realms: []
tags:
  - meta
---

# CWF — Overview

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

**Site: `CWF-US`**
```
plugin_sitemap:app_cwf:app_cwf_front:app_giftcert:app_returns:int_sitemap_custom:int_adyen_custom:app_adyen_SFRA:int_adyen_SFRA:int_adyen_webhooks:plugin_blog:plugin_wishlists:plugin_dis:lib_productlist:app_storefront_base
```

**Site: `CWF-EMEA`**
```
plugin_sitemap:int_sitemap_custom:app_EMEA:app_cwf:app_cwf_front:app_giftcert:app_returns:int_adyen_custom:app_adyen_SFRA:int_adyen_SFRA:int_adyen_webhooks:int_chronopost:int_colissimo:int_netreviews_sfra:int_iadvize:int_storelocator:int_faibrik:plugin_blog:plugin_wishlists:plugin_dis:lib_productlist:app_storefront_base:int_osflicensemanager
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
FROM "10-Clients/<ClientName>"
WHERE (type = "tsd" OR type = "plan") AND status != "archived"
SORT date DESC
```

## Recent incidents

```dataview
TABLE summary, severity, date
FROM "10-Clients/<ClientName>"
WHERE type = "incident"
SORT date DESC
LIMIT 10
```

## Recent reviews

```dataview
TABLE pr, file.link AS Review, status, severity, date
FROM "10-Clients/<ClientName>"
WHERE type = "review"
SORT date DESC
LIMIT 10
```

## Notes / gotchas

> Tribal knowledge that doesn't fit anywhere else. Things future-you would have wanted to know.

- 

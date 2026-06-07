---
type: client-overview
client: Baccarat
status: active
sfcc-version: "26.5"
sfra-version: "7.1"
sites:
  - NORA
  - EUROPE
  - JAPAN
  - APAC
  - MIDDLEEAST
  - INT
realms: []
tags:
  - meta
---

# Baccarat — Overview

> Replace Baccarat everywhere and rename this folder.

## Stack snapshot

- **SFCC version:** 
- **SFRA version:** 22.7
- **PWA Kit / headless?** no
- **Realms:** 
- **Sites:** 
- **Locales:** 
- **Currencies:** 

## Cartridge path

> Document the canonical cartridge path order for each site. Order matters — it's the overlay precedence.

**Site: `NORA`**
```
app_baccarat_neurope:app_baccarat:int_cbt:int_custom_jobs:int_custom_services:bc_job_components:plugin_dis:int_b2ccrmsync:int_vertex:int_dqe:app_adyen_SFRA:int_adyen_SFRA:int_ekata:bm_refunds:int_backinstock_baccarat:int_backinstock:int_marketing_cloud:int_handlerframework:int_beecloud_recaptcha:bm_reports:plugin_wishlists:lib_productlist:app_storefront_base:plugin_sitemap
```

**Site: `EUROPE`**
```
app_baccarat_neurope:app_baccarat:int_cbt:int_custom_jobs:int_custom_services:bc_job_components:plugin_dis:int_b2ccrmsync:int_vertex:int_dqe:app_adyen_SFRA:int_adyen_SFRA:int_ekata:bm_refunds:int_backinstock_baccarat:int_backinstock:int_marketing_cloud:int_handlerframework:int_beecloud_recaptcha:bm_reports:plugin_wishlists:lib_productlist:app_storefront_base:plugin_sitemap
```

**Site: `JAPAN`**
```
app_baccarat_japan:app_baccarat:int_cbt:int_custom_jobs:int_custom_services:bc_job_components:plugin_dis:int_b2ccrmsync:int_dqe:app_adyen_SFRA:int_adyen_SFRA:bm_refunds:int_backinstock_baccarat:int_backinstock:int_marketing_cloud:int_handlerframework:int_beecloud_recaptcha:bm_reports:plugin_wishlists:lib_productlist:app_storefront_base:plugin_sitemap
```

**Site: `APAC`**
```
app_baccarat_apac:app_baccarat:int_cbt:int_custom_jobs:int_custom_services:bc_job_components:plugin_dis:int_b2ccrmsync:int_dqe:app_adyen_SFRA:int_adyen_SFRA:bm_refunds:int_backinstock_baccarat:int_backinstock:int_marketing_cloud:int_handlerframework:int_beecloud_recaptcha:bm_reports:plugin_wishlists:lib_productlist:app_storefront_base:plugin_sitemap
```

**Site: `MIDDLEEAST`**
```
app_baccarat_middleeast:app_baccarat:int_cbt:int_custom_jobs:bc_job_components:plugin_dis:int_b2ccrmsync:int_dqe:app_adyen_SFRA:int_adyen_SFRA:int_backinstock_baccarat:int_backinstock:int_marketing_cloud:int_handlerframework:int_beecloud_recaptcha:bm_reports:plugin_wishlists:lib_productlist:app_storefront_base:plugin_sitemap
```

**Site: `INT`**
```
app_baccarat_neurope:app_baccarat:int_cbt:int_custom_jobs:bc_job_components:plugin_dis:int_b2ccrmsync:int_vertex:app_adyen_SFRA:int_adyen_SFRA:int_backinstock_baccarat:int_backinstock:int_marketing_cloud:int_handlerframework:int_beecloud_recaptcha:bm_reports:plugin_wishlists:lib_productlist:app_storefront_base:plugin_sitemap
```


## Business Manager access

- BM URL: 
- SSO / IdP: 
- Roles I have: Administrator

## Key integrations

> Link to one note per integration in `Integrations/`.

- [[Integrations/oms-<vendor>]]
- [[Integrations/pim-<vendor>]]
- [[Integrations/payment-<vendor>]]
- [[Integrations/auth-<vendor>]]

## Deployment

- **VCS:** GitHub
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

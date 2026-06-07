---
type: client-overview
client: <ClientName>
status: active        # active | offboarded
sfcc-version: <e.g. 24.6>
sfra-version: <e.g. 7.1>
sites: []
realms: []
tags: [meta]
---

# <ClientName> — Overview

> Replace `<ClientName>` everywhere and rename this folder.

## Stack snapshot

- **SFCC version:** 
- **SFRA version:** 
- **PWA Kit / headless?** no / yes (version: )
- **Realms:** 
- **Sites:** 
- **Locales:** 
- **Currencies:** 

## Cartridge path

> Document the canonical cartridge path order for each site. Order matters — it's the overlay precedence.

**Site: `<site-id>`**
```
int_custom_<feature> : app_<client>_storefront : app_storefront_base : modules
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

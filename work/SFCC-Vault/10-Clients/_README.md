---
type: meta
tags: [meta]
---

# Clients

One folder per client. All client-specific work lives here.

## Setup a new client

1. Copy `_template-client/` to `<ClientName>/`
2. Open `<ClientName>/_overview.md`, replace all `<ClientName>` placeholders
3. Fill in stack snapshot, cartridge path, BM access
4. Symlink health reports: `~/sfcc-reports/<ClientName>/` → `<ClientName>/Health-Reports/`
5. Add to `00-Index/Active-Projects.md` if not auto-picked-up by Dataview

## Confidentiality

If a client requires it, keep their folder in a **separate vault** with local-only sync. TSDs and reviews often contain code, system object names, and integration details that some clients consider confidential.

## Active clients

```dataview
TABLE sfcc-version, sfra-version, status
FROM "10-Clients"
WHERE type = "client-overview" AND status = "active"
SORT file.name ASC
```

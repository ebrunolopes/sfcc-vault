---
type: integration
client: Baccarat
system: SFCC Dev MCP Server
direction: outbound
protocol: REST
auth: basic + oauth2
status: active
tags: [observability, integration]
---

# SFCC MCP — Baccarat

MCP integration for log analysis, system object exploration, and health checks on Baccarat's
SFCC instances.

## Environments

| Env     | MCP name        | Hostname | OCAPI Data API |
|---------|-----------------|----------|----------------|
| Dev     | `sfcc-bcrt-dev`  | `<fill-hostname>` | configured / not configured |
| Staging | `sfcc-bcrt-stg`  | `<fill-hostname>` | configured / not configured |
| Prod    | `sfcc-bcrt-prod` | `<fill-hostname>` | configured / not configured |

## Credential location

All credentials stored in `~/.sfcc-credentials/baccarat/`:

```
~/.sfcc-credentials/baccarat/
├── dev.dw.json
├── staging.dw.json
└── prod.dw.json
```

⚠️ **Do not record credentials here.** This note tracks hostnames, MCP names, and setup status.
Secrets live only in the `dw.json` files above, which are never synced.

## OCAPI Data API status

| Environment | Client ID registered | BM resources configured | Notes |
|---|---|---|---|
| Dev | yes / no | yes / no | |
| Staging | yes / no | yes / no | |
| Prod | yes / no | yes / no | |

Client IDs are registered in Account Manager (not BM). Record the client ID here (not the secret):
- Dev client ID: `<fill>`
- Staging client ID: `<fill>`
- Prod client ID: `<fill>`

## Integrations monitored in health checks

The health check skill scans for these integration keywords in the logs:

| Integration | Keywords | Notes |
|---|---|---|
| Adyen | `Adyen` | Payment processing |
| Vertex | `Vertex` | Tax calculation |
| CRM Sync | `b2ccrmsync`, `CRMSync` | Customer data sync |
| Back-in-stock | `BackInStock`, `back-in-stock` | Notification service |
| Pricebook | `pricebook`, `PriceBook` | Price import |

Add client-specific integrations here if Baccarat has services not in the default list.

## Credential rotation schedule

| Credential | Rotation cadence | Last rotated | Notes |
|---|---|---|---|
| BM username/password (dev) | per policy | | |
| BM username/password (stg) | per policy | | |
| BM username/password (prod) | per policy | | |
| OCAPI client secret (dev) | per policy | | |
| OCAPI client secret (stg) | per policy | | |
| OCAPI client secret (prod) | per policy | | |

After rotation: update `~/.sfcc-credentials/baccarat/<env>.dw.json`. No MCP re-registration needed.

## Access notes

- VPN required: yes / no
- IP allowlist: 
- Special BM permissions needed: 
- Account Manager access: who can generate client secrets

## Setup verification commands

```bash
# Verify MCP is registered
claude mcp list | grep bcrt

# Test docs mode
# In Claude Code: "Show methods on dw.catalog.Product"

# Test full mode (dev)
# In Claude Code: "Summarize today's logs on sfcc-bcrt-dev"
```

## Related

- [[../../60-Runbooks/sfcc-mcp-setup|MCP setup runbook]]
- [[../../60-Runbooks/new-machine-setup|New machine setup]]

---
type: integration
client: MyO
system: SFCC Dev MCP Server
direction: outbound
protocol: REST
auth: basic + oauth2
status: active
tags: [observability, integration]
---

# SFCC MCP — MyO

MCP integration for log analysis, system object exploration, and health checks on MyO's
SFCC instances.

## Environments

| Env     | MCP name        | Hostname | OCAPI Data API |
|---------|-----------------|----------|----------------|
| Dev     | `sfcc-myo-dev`  | `<fill-hostname>` | configured / not configured |
| Staging | —               | — | — (no staging MCP configured) |
| Prod    | —               | — | — (no prod MCP configured) |

## Credential location

```
~/.sfcc-credentials/myo/
└── dev.dw.json
```

⚠️ **Do not record credentials here.** Secrets live only in the `dw.json` files above.

## OCAPI Data API status

| Environment | Client ID registered | BM resources configured | Notes |
|---|---|---|---|
| Dev | yes / no | yes / no | |

Client IDs (not secrets):
- Dev client ID: `<fill>`

## Integrations monitored in health checks

| Integration | Keywords | Notes |
|---|---|---|
| Adyen | `Adyen` | |
| Vertex | `Vertex` | |
| CRM Sync | `b2ccrmsync`, `CRMSync` | |
| Back-in-stock | `BackInStock`, `back-in-stock` | |
| Pricebook | `pricebook`, `PriceBook` | |

Add MyO-specific integrations if they differ from defaults.

## Credential rotation schedule

| Credential | Rotation cadence | Last rotated | Notes |
|---|---|---|---|
| BM username/password (dev) | per policy | | |
| OCAPI client secret (dev) | per policy | | |

## Access notes

- VPN required: yes / no
- IP allowlist:
- Special BM permissions needed:

## Related

- [[../../60-Runbooks/sfcc-mcp-setup|MCP setup runbook]]

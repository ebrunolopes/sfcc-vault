---
type: integration
client: <ClientName>
system: <vendor / system name>
direction: outbound  # outbound | inbound | bidirectional
protocol: REST       # REST | SOAP | SFTP | webhook | other
auth: oauth2         # oauth2 | basic | api-key | mtls | other
status: active
tags: [service, integration]
---

# Integration — <system name>

## Purpose

Why this integration exists. One paragraph.

## Endpoints

| Operation | Method | URL | Profile name |
|---|---|---|---|
| | | | |

## Service configuration

- **Service ID:** `<service-id>` in BM > Administration > Operations > Services
- **Profile:** timeout, retry, circuit breaker settings
- **Credentials:** stored in BM Service Credentials (do NOT paste secrets here)

## Code touchpoints

- Service definition: `cartridges/<cartridge>/cartridge/scripts/services/<service>.js`
- Callers: 

## Error handling

- Retry strategy: 
- Circuit breaker thresholds: 
- Fallback behavior: 
- Logging: `Logger.getLogger('<category>', '<file>')`

## Observability

- Custom log file: 
- Metrics tracked: 
- Alerts: 

## Operational notes

- Rate limits (theirs): 
- Maintenance windows: 
- Vendor contact: 
- SLA:

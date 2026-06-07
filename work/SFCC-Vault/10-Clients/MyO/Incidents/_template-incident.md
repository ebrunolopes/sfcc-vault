---
type: incident
client: <ClientName>
date: <YYYY-MM-DD>
severity: SEV2       # SEV1 | SEV2 | SEV3 | SEV4
status: investigating  # investigating | mitigated | resolved | closed
summary: <one-line summary>
duration-minutes: 
detected-by: monitoring | customer | engineer
related-prs: []
related-reviews: []
tags: [<domain-area>, observability, incident]
---

# INC-<YYYY-MM-DD>-<kebab-slug>

## Summary

One paragraph. What happened, who was affected, for how long.

## Timeline

| Time (UTC) | Event |
|---|---|
| HH:MM | First signal in logs |
| HH:MM | Alert fired |
| HH:MM | Investigation started |
| HH:MM | Mitigation deployed |
| HH:MM | Fully resolved |

## Impact

- Users affected: 
- Sites affected: 
- Revenue impact (if known): 
- SLA breach: yes / no

## Root cause

> Not a guess. The actual cause, traced. Reference the 4-phase debugging methodology if applicable.

## Contributing factors

Things that made it worse or harder to detect.

- 

## What went well

- 

## What didn't

- 

## Action items

- [ ] Code fix — owner, due
- [ ] Monitoring gap — owner, due
- [ ] Runbook update — owner, due
- [ ] ADR if architectural — owner, due

## Links

- Logs / dashboards: 
- PR / fix: 
- Related runbook:

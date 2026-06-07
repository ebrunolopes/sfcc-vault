---
type: runbook
date: <YYYY-MM-DD>
status: active       # active | needs-review | deprecated
last-verified: <YYYY-MM-DD>
estimated-time: <e.g. 15 min>
tags: [<domain-area>, observability, runbook]
---

# Runbook — <action verb + noun, e.g. "Investigate OCAPI 500 spike">

## When to use this

Trigger conditions. Be specific: "OCAPI 5xx error rate > 2% for 5+ minutes."

## Prerequisites

- BM access to: 
- Tooling: 
- Permissions: 

## Steps

1. **Step.** Action. Expected result.
   ```bash
   # exact command if relevant
   ```
2. **Step.** …
3. **Step.** …

## Decision tree

```
If <condition>:
  → go to step X
Else if <condition>:
  → go to step Y
Else:
  → escalate
```

## Escalation

- Slack channel: 
- On-call: 
- Vendor contact:

## Related

- [[../10-Clients/.../Incidents/...]] — past incidents that used this runbook
- [[../60-Runbooks/...]] — adjacent runbooks

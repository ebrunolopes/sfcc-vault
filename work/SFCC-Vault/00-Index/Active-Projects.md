---
type: index
tags: [meta]
---

# Active Projects

All in-flight SFCC work, grouped by client. Filtered to non-archived TSDs and Plans.

## By client

```dataview
TABLE WITHOUT ID file.link AS Note, type, status, date
FROM "10-Clients"
WHERE (type = "tsd" OR type = "plan") AND status != "archived"
SORT client ASC, date DESC
GROUP BY client
```

## Recently updated (any type)

```dataview
TABLE client, type, status
FROM "10-Clients"
SORT file.mtime DESC
LIMIT 20
```

---
type: meta
tags: [meta]
---

# Snippets

Pure code, no narrative. Drop-in starting points.

## Conventions

- Filenames describe shape: `controller-template.js`, `model-decorator-template.js`
- Top comment block explains: file path, cartridge it belongs in, what to rename
- No client-specific code here — that lives in `10-Clients/`
- Patterns explain *why*; snippets just show *what*

## Index

```dataview
LIST
FROM "50-Snippets"
WHERE type = "snippet"
SORT file.name ASC
```

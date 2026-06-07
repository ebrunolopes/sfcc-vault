---
type: runbook
date: 2026-05-28
status: active
last-verified: 2026-05-28
estimated-time: 15 min
tags: [observability, runbook]
---

# Runbook — SFCC MCP server setup

How to register SFCC Dev MCP servers in Claude Code for log analysis, system object exploration,
and health checks across multiple clients and environments.

MCP server: [sfcc-dev-mcp](https://sfcc-mcp-dev.rhino-inquisitor.com/) by Thomas Theunen (MIT).
Source: [github.com/taurgis/sfcc-dev-mcp](https://github.com/taurgis/sfcc-dev-mcp)

## Prerequisites

- Claude Code installed and authenticated (personal account)
- Node.js 18+ (for `npx`)
- BM credentials (username/password) for each SFCC instance
- OCAPI client-id / client-secret if you need system objects, site prefs, or code version access

## MCP servers registered

Update this table as you add new clients or environments.

| Name            | Scope   | Mode | Credential path                                 | Notes |
|-----------------|---------|------|-------------------------------------------------|-------|
| sfcc-docs       | user    | docs | (none)                                          | Docs only, no credentials, always available |
| sfcc-bcrt-dev   | project | full | `~/.sfcc-credentials/baccarat/dev.dw.json`      | |
| sfcc-bcrt-stg   | project | full | `~/.sfcc-credentials/baccarat/staging.dw.json`  | |
| sfcc-bcrt-prod  | project | full | `~/.sfcc-credentials/baccarat/prod.dw.json`     | |
| sfcc-cwf-dev    | project | full | `~/.sfcc-credentials/cwf/dev.dw.json`           | |
| sfcc-cwf-stg    | project | full | `~/.sfcc-credentials/cwf/staging.dw.json`       | |
| sfcc-myo-dev    | project | full | `~/.sfcc-credentials/myo/dev.dw.json`           | |

## Credential file structure

```
~/.sfcc-credentials/              ← LOCAL ONLY — never synced, never committed
├── baccarat/
│   ├── dev.dw.json
│   ├── staging.dw.json
│   └── prod.dw.json
├── cwf/
│   ├── dev.dw.json
│   └── staging.dw.json
└── myo/
    └── dev.dw.json
```

Each file follows the `dw.json` format:

```json
{
  "hostname": "<instance>.commercecloud.salesforce.com",
  "username": "<bm-username>",
  "password": "<bm-password>",
  "client-id": "<ocapi-client-id>",
  "client-secret": "<ocapi-client-secret>"
}
```

Minimum for log access (WebDAV): `hostname`, `username`, `password`.
Full access (system objects, site prefs, code versions): add `client-id`, `client-secret`.

### Security

```bash
# Lock down permissions — owner-only read/write
chmod 700 ~/.sfcc-credentials
chmod 700 ~/.sfcc-credentials/*/
chmod 600 ~/.sfcc-credentials/*/*.dw.json
```

⚠️ **NEVER put credentials in the vault, in a git repo, or in any synced folder.**
The vault stores the *pattern* and *MCP names*. Secrets live only in `~/.sfcc-credentials/`.

## Install — docs-only server (global)

```bash
claude mcp add --scope user sfcc-docs -- npx sfcc-dev-mcp
```

Available in every Claude Code session. No credentials. Good for API doc lookups, ISML reference, cartridge scaffolding.

Verify:

```bash
claude mcp list
# Should show: sfcc-docs
```

In Claude Code:

```
> Show methods on dw.catalog.Product for pricing
```

Should return real SFCC API documentation.

## Install — authenticated servers (per-client)

### Step 1 — Create the credential directory

```bash
mkdir -p ~/.sfcc-credentials/baccarat
chmod 700 ~/.sfcc-credentials ~/.sfcc-credentials/baccarat
```

### Step 2 — Create the dw.json

```bash
# Use your editor — don't echo secrets into bash history
code ~/.sfcc-credentials/baccarat/dev.dw.json
# Or: nano, vim, etc.
```

Paste the JSON with your real credentials. Save. Then:

```bash
chmod 600 ~/.sfcc-credentials/baccarat/dev.dw.json
```

### Step 3 — Register the MCP server

```bash
claude mcp add sfcc-bcrt-dev -- npx sfcc-dev-mcp --dw-json ~/.sfcc-credentials/baccarat/dev.dw.json
```

### Step 4 — Restart Claude Code and verify

```bash
claude
```

```
> Summarize today's logs on sfcc-bcrt-dev
```

If log data comes back, the full-mode connection works.

### Step 5 — Repeat for other environments / clients

```bash
# Baccarat staging
claude mcp add sfcc-bcrt-stg -- npx sfcc-dev-mcp --dw-json ~/.sfcc-credentials/baccarat/staging.dw.json

# Baccarat prod
claude mcp add sfcc-bcrt-prod -- npx sfcc-dev-mcp --dw-json ~/.sfcc-credentials/baccarat/prod.dw.json

# CWF dev
claude mcp add sfcc-cwf-dev -- npx sfcc-dev-mcp --dw-json ~/.sfcc-credentials/cwf/dev.dw.json

# CWF staging
claude mcp add sfcc-cwf-stg -- npx sfcc-dev-mcp --dw-json ~/.sfcc-credentials/cwf/staging.dw.json

# MyO dev
claude mcp add sfcc-myo-dev -- npx sfcc-dev-mcp --dw-json ~/.sfcc-credentials/myo/dev.dw.json
```

## Adding a new client

1. `mkdir -p ~/.sfcc-credentials/<client-slug>`
2. `chmod 700 ~/.sfcc-credentials/<client-slug>`
3. Create `dev.dw.json` (and `staging.dw.json`, `prod.dw.json` as needed) with credentials
4. `chmod 600 ~/.sfcc-credentials/<client-slug>/*.dw.json`
5. `claude mcp add sfcc-<prefix>-<env> -- npx sfcc-dev-mcp --dw-json ~/.sfcc-credentials/<client-slug>/<env>.dw.json`
6. Update the table at the top of this runbook
7. Create an integration note at `<VAULT>/10-Clients/<Client>/Integrations/sfcc-mcp.md`

## Credential rotation

When a BM password or client secret rotates:

1. Update the corresponding `~/.sfcc-credentials/<client>/<env>.dw.json`
2. No MCP re-registration needed — the server reads the file at startup
3. Restart any active Claude Code session to pick up the new credentials

## Removing an MCP server

```bash
claude mcp remove sfcc-bcrt-dev
```

## OCAPI Data API setup (required for system objects, site prefs, code versions)

In BM → Administration → Site Development → Open Commerce API Settings → Data API tab, add the resource mapping for your client-id. Full mapping is documented at:
https://sfcc-mcp-dev.rhino-inquisitor.com/guide/configuration

Key resources needed:

- `/system_object_definitions` and `/system_object_definitions/*` (GET)
- `/system_object_definition_search` (POST)
- `/system_object_definitions/*/attribute_definition_search` (POST)
- `/system_object_definitions/*/attribute_group_search` (POST)
- `/custom_object_definitions/*/attribute_definition_search` (POST)
- `/site_preferences/preference_groups/*/*/preference_search` (POST)
- `/code_versions` and `/code_versions/*` (GET, PATCH)

## Troubleshooting

**"MCP server not found" in Claude Code.** Run `claude mcp list` to verify it's registered. If not listed, re-add it.

**Docs work but logs don't.** The dw.json is missing or has wrong credentials. Check: `cat ~/.sfcc-credentials/<client>/<env>.dw.json` — verify hostname, username, password.

**403 on system objects / site prefs.** Missing OCAPI Data API resource mapping in BM. See the OCAPI section above.

**401 on everything.** Credentials expired or wrong. Update the dw.json. If using client-id/client-secret, verify the secret hasn't been regenerated in Account Manager.

**Slow first run.** `npx sfcc-dev-mcp` downloads the package on first use. Subsequent runs are cached. If you want to pre-install globally: `npm install -g sfcc-dev-mcp`.

## On a new machine

1. Install Claude Code: `npm install -g @anthropic-ai/claude-code`
2. Recreate `~/.sfcc-credentials/` from your password manager (structure shown above)
3. Run `claude mcp add --scope user sfcc-docs -- npx sfcc-dev-mcp`
4. Run each `claude mcp add sfcc-<prefix>-<env> ...` command from the table above
5. Verify: `claude mcp list`
6. Restart Claude Code and test one connection

## Related

- [[../10-Clients/Baccarat/Integrations/sfcc-mcp|Baccarat MCP integration note]]
- [[../10-Clients/CWF/Integrations/sfcc-mcp|CWF MCP integration note]]
- [[../10-Clients/MyO/Integrations/sfcc-mcp|MyO MCP integration note]]
- [[new-machine-setup|New machine setup runbook]]

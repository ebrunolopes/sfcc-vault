---
type: tsd
client: <ClientName>
project: <project-slug>
date: <YYYY-MM-DD>
status: draft                  # draft | active | superseded | archived
sfcc-version: 
sfra-version: 
frontend-stack: sfra           # sfra | pwa-kit | storefront-next
authors: []
related-prs: []
related-tickets: []            # e.g. BCRTR-1558
related-adrs: []
related-tsds: []
ticket-snapshot-date:          # when ticket context was last pulled in
tags: [<domain-area>, <concern>, tsd]
---

# TSD — <feature / project title>

> Filename: `TSD-YYYY-MM-DD-<kebab-slug>.md`
>
> Fill placeholders. Mark a section **"N/A — not applicable to this change"** if genuinely
> out of scope; never silently omit it. Use **⚠️** for architectural risks and **🔴 DEPRECATED**
> for legacy patterns (pipelines, OCAPI-where-SCAPI-fits, etc.).

---

## 1. Context & purpose

**Business goal.** One paragraph. What we're building, why now, the outcome it serves.

**Scope statement.**
- **In scope:**
- **Out of scope:**

## 2. Goals & non-goals

**Goals**
- 

**Non-goals**
- 

## 3. Stakeholders

| Role | Name | Notes |
|---|---|---|
| Product owner | | |
| Tech lead | | |
| QA lead | | |
| Client side | | |
| Other | | |

## 4. Current state

How the system behaves today. Reference existing controllers, models, jobs, integrations.
Link to relevant files (cartridge-relative paths). Call out the parts of the current state
this change leaves alone vs. the parts it replaces.

## 5. Proposed design

### 5.1 Architecture summary

One diagram + one paragraph. Use Mermaid or link to `Architecture/`.

### 5.2 Cartridge impact

| Cartridge | Status | Notes |
|---|---|---|
| `app_<client>_storefront` | modified | new controller override |
| `int_<feature>` | added | new integration cartridge |

- Cartridge path order changes: 
- Multi-site / locale scope: 
- Frontend stack: SFRA / PWA Kit / Storefront Next

### 5.3 SFRA touchpoints

| Layer | File (cartridge-relative) | Change |
|---|---|---|
| Controller | `cartridges/app_<client>_storefront/cartridge/controllers/X.js` | append / prepend / replace |
| Model | `…/models/X.js` | new / extend |
| Decorator | `…/models/decorators/X.js` | new |
| ISML | `…/templates/default/X.isml` | new / modify |
| Service | `…/scripts/services/X.js` | new |
| Hook | `…/scripts/hooks/X.js` (registered in `package.json`) | new |
| Job | `…/scripts/jobs/X.js` + `steptypes.json` | new |

### 5.4 Data model

#### System object extensions

| Object | Attribute ID | Type | Localizable | Searchable | Mandatory | Default |
|---|---|---|---|---|---|---|

#### Custom objects

| Object | Key attribute | Replication policy | Notes |
|---|---|---|---|

#### Site preferences

| ID | Type | Default | BM visibility group | Notes |
|---|---|---|---|---|

**Migration / backfill.** Any data migration required?

### 5.5 Service & integration design

For each new or modified service:

| Field | Value |
|---|---|
| Service ID (LocalServiceRegistry) | |
| Protocol | HTTP / HTTPS / FTP / SOAP |
| Auth | Basic / OAuth 2.0 client credentials / API key / mTLS |
| Timeout (ms) | |
| Retry policy | |
| Circuit breaker | |
| Service profile path | `<cartridge>/cartridge/scripts/init/<Service>.js` |
| Mock / stub path | `test/mocks/services/<Service>.js` |

**Request / response shape.** Brief skeleton or field table.

### 5.6 OCAPI / SCAPI hooks

| Hook ID | Script path | Registered in | Notes |
|---|---|---|---|
| e.g. `dw.ocapi.shop.order.calculate` | `cartridges/.../hooks/order/calculate.js` | `package.json` | |

- OCAPI permission changes in BM → Administration → OCAPI Settings: 
- 🔴 **DEPRECATED migration candidates** — OCAPI hooks that should move to SCAPI / Custom APIs:

### 5.7 Jobs & schedules

For each new or modified job:

| Field | Value |
|---|---|
| Job ID | |
| Description | |
| Step type | `ExecuteScriptModule` / chunk-oriented / pipeline (🔴 DEPRECATED) |
| Script path | `…/scripts/jobs/X.js` |
| Exported function | `function execute(parameters, stepExecution) { ... }` |
| Chunk-oriented? | yes / no |
| Schedule (cron) | |
| Parameters | name : type = default |
| Idempotency | safe-to-re-run? yes / no, why |

### 5.8 Business Manager configuration

- New BM modules / menu extensions: 
- Permission groups required: 
- Import/export XML snippets (site prefs, services, jobs):
- Content Asset / Page Designer component registration:

### 5.9 Security

| Concern | Detail |
|---|---|
| Input validation | Where user/external input is validated |
| Output encoding | ISML `${...}` default; any `encoding="off"` (must be justified) |
| CSRF | Forms requiring CSRF token; server-side verification |
| Authentication | Routes requiring `URLUtils.https()`; session checks |
| Authorization | `CustomerMgr` / role checks before sensitive operations |
| Sensitive data | PII handling, PCI scope (card data must never touch custom code) |
| Dependency security | New npm / require-js packages; CVE check |

### 5.10 Performance & caching

- Page / partial / remote-include / custom-cache strategy: 
- Cache invalidation triggers: 
- Expected request volume / peak load: 
- N+1 risks reviewed: yes / no, where
- `SystemObjectMgr.querySystemObjects` calls in loops? cached?
- Custom object / search index notes: 
- Pagination strategy: 

### 5.11 Accessibility (WCAG 2.1 AA)

- Keyboard navigation: 
- Screen reader behaviour: 
- Color contrast: 
- ARIA usage (only where native semantics insufficient):
- Form labels and error announcement:

### 5.12 Observability

- Custom log category / file: `Logger.getLogger('<category>', '<file>')`
- Log levels in use: 
- Custom metrics / quotas: 
- Alert thresholds (if applicable):

## 6. Alternatives considered

| Option | Pros | Cons | Decision |
|---|---|---|---|
| A | | | chosen / rejected |
| B | | | chosen / rejected |

Non-obvious decisions become ADRs in `20-ADRs/` and get linked in frontmatter (`related-adrs`).

## 7. Risks & assumptions

| ⚠️ Risk | Impact | Mitigation |
|---|---|---|

**Assumptions.** Things we're treating as given, that should be verified:
- 

## 8. Testing strategy

- **Unit (mocha/chai/sinon):** which scripts/models are covered; test file paths
- **Integration:** controller routes exercised, mock service stubs
- **Manual QA checklist:** key user journeys
- **Regression risk areas:** what existing functionality could break
- **Load testing:** required? scenarios?

## 9. Deployment & rollback

**Deployment order.**
1. Metadata upload (system object extensions, services, jobs)
2. Code version activation
3. Job run / data migration (if applicable)
4. BM configuration (site prefs, permission groups)

- **Feature flag / dark-launch toggle:** 
- **Rollback procedure:** prior code version + data model cleanup steps
- **Post-deployment smoke tests:** 

## 10. Open questions

- [ ] 
- [ ] 

Use checkboxes — track them down before status moves from `draft` to `active`.

## 11. Links

- **PRs:** 
- **Tickets:** 
- **Related TSDs:** 
- **Related ADRs:** 
- **Reference docs:** 
- **Architecture diagrams:** 

---

## Quality checklist

Run before flipping `status` from `draft` to `active`:

- [ ] All 11 sections present (or explicitly marked **N/A**)
- [ ] All service IDs, hook IDs, custom-object names match the code
- [ ] Security section addresses all 7 concerns
- [ ] No OCAPI hooks left un-flagged for potential SCAPI / Custom API migration
- [ ] Multi-site / locale scope is clearly stated
- [ ] Deployment order is explicit and reversible
- [ ] Cartridge-relative paths used (no absolute paths)
- [ ] No invented details — unknowns marked "TBD — requires confirmation from <role>"
- [ ] Frontmatter complete: `client`, `date`, `status`, `tags`, `related-prs` or `related-tickets`
- [ ] ⚠️ risks identified or explicitly stated as "none"
- [ ] 🔴 DEPRECATED patterns flagged with rationale and migration path

---

## Tone & style (for the author)

- Audience: senior SFCC engineers and technical project managers
- Precise, concise — one sentence per concept where possible
- Use SFCC terminology (cartridge, site preference, hook, job step) without explanation
- **⚠️** inline for architectural risks
- **🔴 DEPRECATED** inline for legacy patterns (pipelines, OCAPI-where-SCAPI-fits)
- Cartridge-relative paths, never absolute

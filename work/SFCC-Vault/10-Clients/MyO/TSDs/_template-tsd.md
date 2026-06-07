---
type: tsd
client: <ClientName>
project: <project-slug>
date: <YYYY-MM-DD>
status: draft        # draft | active | superseded | archived
sfcc-version: 
sfra-version: 
authors: []
related-prs: []
related-adrs: []
tags: [<domain-area>, <concern>, tsd]
---

# TSD — <feature/project title>

> Filename: `TSD-YYYY-MM-DD-<kebab-slug>.md`
> Replace placeholders. Keep sections you use, delete the ones you don't.

## 1. Context & problem

What we're building, why now, what business outcome it serves. One paragraph.

## 2. Goals & non-goals

**Goals**
- 

**Non-goals**
- 

## 3. Stakeholders

| Role | Name |
|---|---|
| Product owner | |
| Tech lead | |
| QA | |
| Client side | |

## 4. Current state

How the system behaves today. Reference existing controllers, models, jobs, integrations. Link to relevant files (cartridge-relative paths).

## 5. Proposed design

### 5.1 Architecture summary

> One diagram + one paragraph. Use Mermaid or link to `Architecture/`.

### 5.2 SFRA touchpoints

| Layer | File (cartridge-relative) | Change |
|---|---|---|
| Controller | `cartridges/app_<client>_storefront/cartridge/controllers/X.js` | append/prepend/replace |
| Model | `…/models/X.js` | new / extend |
| Decorator | `…/models/decorators/X.js` | new |
| ISML | `…/templates/default/X.isml` | new / modify |
| Service | `…/scripts/services/X.js` | new |
| Hook | `…/scripts/hooks/X.js` (registered in `package.json`) | new |
| Job | `…/scripts/jobs/X.js` + `steptypes.json` | new |

### 5.3 Data model

System object extensions, custom objects, attribute definitions. Include type, mandatory flag, default, BM-visible flag.

### 5.4 Integrations

| System | Direction | Protocol | Auth | Retry / circuit breaker |
|---|---|---|---|---|

### 5.5 Security

- Input validation: 
- Output encoding: ISML default encoding kept on
- CSRF: 
- AuthN/AuthZ: 
- PII handling: 

### 5.6 Performance

- Caching: page / partial / remote-include / custom-cache
- Expected request rate: 
- N+1 risks reviewed: yes/no, where
- Pagination strategy: 

### 5.7 Accessibility

- WCAG 2.1 AA target
- Keyboard nav: 
- Screen reader behavior: 
- Color contrast: 

### 5.8 Observability

- Custom log file: 
- Log levels: 
- Custom metrics / quotas: 

## 6. Alternatives considered

| Option | Pros | Cons | Decision |
|---|---|---|---|
| A | | | chosen / rejected |
| B | | | chosen / rejected |

> Non-obvious decisions become ADRs in `20-ADRs/`. Link them in frontmatter.

## 7. Rollout plan

- Feature flag / preference: 
- Phased rollout: 
- Rollback strategy: 
- Code version & deployment window: 

## 8. Testing strategy

- Unit (mocha/chai/sinon): 
- Integration: 
- Manual QA: 
- Load: 

## 9. Open questions

- [ ] 
- [ ] 

## 10. Links

- PRs: 
- Jira / tickets: 
- Related TSDs: 
- Related ADRs: 
- Reference docs:

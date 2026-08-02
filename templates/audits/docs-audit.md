<!-- Source: ApexYard · templates/audits/docs-audit.md · github.com/me2resh/apexyard · MIT -->

# Documentation Audit — {project} @ {short-sha}

> Persisted by `/docs-audit` via `_lib-audit-history.sh`. Frontmatter (above) is structured; the body is freeform per dimension. See `docs/agdr/AgDR-0019-audit-artefact-persistence.md` for the schema rationale.

## Scope

Documentation completeness against the [Diataxis framework](https://diataxis.fr/) (tutorials / how-to guides / reference / explanation) plus README quality and staleness.

## Findings by Diataxis quadrant

### Tutorials (learning-oriented)

| # | Item | Status | Detail | Severity |
|---|---|---|---|---|
| D1 | "Getting started" tutorial | WARN | README has install steps but doesn't walk through a complete user flow | medium |

### How-to guides (task-oriented)

| # | Item | Status | Detail | Severity |
|---|---|---|---|---|
| D2 | Common task recipes | FAIL | No `docs/how-to/` dir; recipes live in scattered Slack threads | high |

### Reference (information-oriented)

| # | Item | Status | Detail | Severity |
|---|---|---|---|---|
| D3 | API reference | PASS | OpenAPI spec at `docs/openapi.yaml`, rendered by Swagger UI | — |
| D4 | Configuration reference | WARN | Env-var list exists but lacks default values + types | medium |

### Explanation (understanding-oriented)

| # | Item | Status | Detail | Severity |
|---|---|---|---|---|
| D5 | Architecture overview | WARN | C4 L1 + L2 diagrams exist; no narrative explaining trade-offs | medium |
| D6 | ADR / AgDR collection | PASS | 12 AgDRs in `docs/agdr/`, indexed | — |

## README quality

Audited against `.claude/rules/readme-quality.md`. Judge content, not headings — a section that exists but says nothing is a finding.

### The four reader questions

| # | Question | Status | Detail | Severity |
|---|---|---|---|---|
| R1 | What is this? | WARN | Opens with "Built with React, FastAPI and Postgres" — names the stack, not the user or the problem. No demo: nothing shows it working without a clone + install. | medium |
| R2 | Does it work? | FAIL | Retrieval-backed search with no evaluation — no dataset, no baseline, no metrics. Output is visible but unverifiable. Test command present and correct. | high |
| R3 | Can I run it? | FAIL | `npm run dev` is not in `package.json` (the real script is `dev:local`). 12 vars in `.env.example`, 3 documented, and required-vs-optional isn't distinguished. | high |
| R4 | How was it built? | WARN | Architecture diagram present but unexplained; no rationale recorded for the datastore choice. CI/CD section accurate. | medium |

### Honesty rails

| # | Rail | Status | Detail | Severity |
|---|---|---|---|---|
| R5 | Present tense = ships today | FAIL | "Real-time sync keeps every device current" — unimplemented; no sync code in the repo. Actively misleads. | high |
| R6 | Absences stated, not omitted | WARN | No monitoring section and no monitoring in the repo — omission reads as capability. One honest sentence under Limitations closes it. | medium |

<!-- Scale to the project before reporting a gap: a CLI tool legitimately has
     no evaluation or monitoring section. A *silently omitted* absence is still
     a finding — that's R6, not proportionality. -->

**Score impact.** This section now judges content rather than section presence, so a README that previously scored one WARN can drop sharply on its first audit under the new bar with no documentation change. That is a re-baseline, not a regression — say so in the Notes when `audit_render_trend` shows the step down.

## Staleness

Files older than 6 months that haven't been touched: `docs/architecture/c4-context.md` (12 months — likely stale post the platform migration), `README.md` § "Tech stack" (still says React 17 — actually React 18 since Q1).

## Recommended priority

1. R5 — delete the "real-time sync" claim or move it to Future Work (minutes; it is the only finding that actively misleads)
2. R3 — fix `npm run dev` → `dev:local` and document the 9 undocumented env vars, marking required vs optional
3. D2 — promote the most-frequently-asked Slack recipes into `docs/how-to/`
4. R2 — evaluation: dataset, baseline, final metrics (largest effort; without it the search quality is a claim, not evidence)
5. D5 — architecture-overview narrative (1-2 hours; pairs well with re-reviewing the C4 diagrams)

## Notes

(Context: doc consumers — internal team, external open-source contributors, paying customers — informs which gaps are highest-impact.)

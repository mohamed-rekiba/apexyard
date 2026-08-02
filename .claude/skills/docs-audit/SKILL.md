---
name: docs-audit
description: Diataxis docs audit — tutorials, how-to, reference, explanation; checks README, API docs, deployment guides, changelog, staleness.
disable-model-invocation: false
argument-hint: "[project-path]"
effort: medium
---

# /docs-audit — Documentation Completeness (Diataxis)

Deep-dive documentation analysis using the Diataxis framework. Checks that docs cover all four quadrants (tutorials, how-to guides, reference, explanation) and are not stale. Invoke when `/launch-check`'s documentation row shows WARN or FAIL.

## Diataxis Framework

| Quadrant | Purpose | What to look for |
|----------|---------|-----------------|
| **Tutorials** | Learning-oriented, guided first steps | Getting started guide, quickstart, "Hello World" |
| **How-to guides** | Goal-oriented, solving specific problems | Deployment guide, migration guide, troubleshooting |
| **Reference** | Information-oriented, accurate description | API docs, config reference, CLI flags, environment variables |
| **Explanation** | Understanding-oriented, why things work | Architecture overview, design decisions (AgDRs), ADRs |

## Process

### Step 1: README quality

Audit `README.md` against [`.claude/rules/readme-quality.md`](../../rules/readme-quality.md) — the framework's README authoring standard — and the shape it authors against, `templates/project-readme.md`.

**Judge content, not headings.** A section that exists but says nothing useful is a finding, not a pass. The most common real-world README failure is a tidy structure wrapped around a stack list and an untested install command.

#### 1a. The four reader questions

A README answers four questions. Score each on whether a reader gets a real answer:

| # | Question | Sections | What a pass looks like |
|---|----------|----------|------------------------|
| 1 | **What is this?** | Description, problem, demo | First sentence names the *user and problem*, not the stack. Reader can see it working without installing. |
| 2 | **Does it work?** | Evaluation, testing, monitoring | Quality claims backed by a dataset and numbers; test command present; absences stated. |
| 3 | **Can I run it?** | Quickstart, configuration, deployment | Prerequisites → clone → install → configure → run. Required vs optional config distinguished. |
| 4 | **How was it built?** | Architecture, structure, decisions, CI/CD | Diagram *with* an explanatory line; consequential decisions carry their trade-offs. |

Plus the tail: **limitations** and **future work**.

**Scale expectations to the project.** A CLI utility legitimately has no evaluation or monitoring section — that is proportionality, not a gap. A retrieval or ML service without evaluation is a real FAIL. Never report a missing section as a finding without first asking whether it applies.

#### 1b. Anti-patterns (each one found is a finding)

| Check | Severity | How to detect |
|-------|----------|---------------|
| Description opens with the tech stack instead of user + problem | medium | Read the first two sentences |
| No demo — live link, video, GIF, screenshot, or worked I/O example | medium | Grep for image/video assets and links near the top |
| Quality-sensitive project with no evaluation | **high** | Does the repo do retrieval / ranking / ML / AI / parsing? Then look for a dataset + metrics |
| Setup commands that don't match the repo's real tooling | **high** | Cross-check every command against `package.json` scripts, `Makefile`, `pyproject.toml`, CI workflow |
| Env vars in `.env.example` / code but undocumented (or documented but unread) | **high** | Diff documented vars against what the code actually reads |
| Work exists in the repo but isn't linked from the README (evaluation, experiments, notebooks, results) | medium | Look for substantial dirs absent from the README |
| Broken links, dead demo URLs, missing image paths | medium | Resolve every link and asset path |
| Present-tense description of an unimplemented feature | **high** | Cross-check claimed capabilities against the code — this is the worst failure, it actively misleads |
| Missing tests / CI / monitoring silently omitted rather than stated | medium | Absent section + absent capability = omission, not proportionality |
| Wall of text — no sections, tables, commands, or visuals | low | Structural read |
| `tree` dump instead of an annotated, simplified structure | low | Look for unannotated full-depth output |
| Undescriptive notebook names (`notebook1.ipynb`, `final_v2.ipynb`) | low | List notebook filenames |

#### 1c. The two honesty rails

These are the failures that make a README *wrong* rather than thin. Report them as **high** severity regardless of how complete the rest of the document is:

1. **Unshipped features described in present tense.** Verify claimed capabilities against the code.
2. **Absences omitted rather than stated.** No tests, no CI, no monitoring — the README must say so. A deleted section reads as "not applicable" and converts a known gap into an implied capability.

#### 1d. Say so when the score re-baselines

This step judges content, not section presence — a stricter bar than the presence-only checklist it replaced. On the **first** run under it, a project whose README previously scored a single WARN can drop sharply with no documentation change at all. `audit_render_trend` will render that as a step down.

It isn't a regression, and reporting it as one wastes the operator's attention. When the previous run for this project predates the new bar, note the re-baseline in the output alongside the trend line.

### Step 2: Every other document

Step 1 covers the front door. This step covers everything behind it — guides, runbooks, rule files, skill docs, reference pages — against [`.claude/rules/docs-quality.md`](../../rules/docs-quality.md), the framework's documentation authoring standard.

Sample rather than exhaust: read the documents a new adopter would actually open (whatever `README.md` and `docs/` index link to first), plus any document changed in the audited range. Judge each on:

| Check | Severity | How to detect |
|-------|----------|---------------|
| Describes enforcement, a gate, or a guarantee that does not exist | **high** | Trace every "enforced by" / "blocks" / "requires" claim to a real hook, test, or CI job — and confirm it blocks rather than warns |
| Present-tense description of an unbuilt capability | **high** | Cross-check claimed behaviour against the code |
| Commands, flags, config keys, or env vars that don't match the repo | **high** | Cross-check against real tooling and the code that reads them |
| **Changelog voice** — "since #N…", "previously…", "this now does…" | medium | Grep for `since #`, `previously`, `used to`, `as of`; each hit is a finding unless the file is an AgDR/ADR, where past tense is correct |
| Mixed Diataxis modes in one document | medium | A tutorial that stops to enumerate options; a reference that narrates |
| Content duplicated from another document rather than linked | medium | Look for repeated tables and paragraphs across files |
| Rules stated without their reason | low | A "always/never do X" with no because-clause |
| Undated relative time — "recently", "soon", "currently" | low | Grep |
| Broken cross-references after a rename | medium | Resolve every relative link |

Report these under the same `D<n>` numbering as the rest of the audit. A document that is merely thin is a low finding; one that describes a gate nobody built is a high one, because readers stop checking the thing themselves.

### Step 3: API documentation (if applicable)

- Check for OpenAPI / Swagger spec (`openapi.yaml`, `swagger.json`)
- Check for auto-generated docs (Swagger UI, Redoc, tsdoc, typedoc)
- Check if endpoints in the code match the spec (any undocumented endpoints?)
- Check for example requests and responses

### Step 4: Operational docs

- Deployment guide: how to deploy, what environment variables are needed
- Runbook: what to do when things go wrong (overlap with `/monitoring-audit`)
- Changelog: is there a CHANGELOG.md? Are releases documented?
- Architecture overview: high-level diagram or description of components
- AgDRs/ADRs: are technical decisions documented?

### Step 5: Staleness detection

- Compare `README.md` last-modified date with recent code changes
- Check if API docs mention endpoints/features that no longer exist
- Check if environment variable docs list vars that are no longer used
- Flag docs that reference deprecated tools, libraries, or patterns

### Step 6: Output

```
DOCS AUDIT — <project> @ <sha>

Diataxis coverage:
  Tutorials:   ✓ getting-started.md exists
  How-to:      ✓ deployment guide, ✗ migration guide, ✗ troubleshooting
  Reference:   ✓ OpenAPI spec (28 endpoints), ✗ env vars undocumented
  Explanation: ✓ 3 AgDRs, ✗ no architecture overview

| # | Area | Status | Finding |
|----|------|--------|---------|
| D1 | README | FAIL | Opens with the stack, not the problem; `npm run dev` isn't in package.json; "real-time sync" described in present tense but unimplemented |
| D2 | API docs | PASS | OpenAPI spec matches code (28/28 endpoints) |
| D3 | Env vars | FAIL | 12 env vars in .env.example, 0 documented in README |
| D4 | Changelog | PASS | CHANGELOG.md updated with last 5 releases |
| D5 | Staleness | WARN | README references "Express" but code migrated to Fastify 3 months ago |

Documentation readiness: PARTIAL (1 fail, 2 warnings)
```

## Persist the run + render trend

After printing the findings table, persist via the shared audit-history lib so the docs trend across runs becomes legible. See `docs/agdr/AgDR-0019-audit-artefact-persistence.md`.

### Resolve project name + score + verdict

`<project-name>` from `apexyard.projects.yaml` (or basename + `/handover` reminder if unregistered).

Score: `score = max(0, 100 - 25*critical - 10*high - 3*medium - 1*low)`. Verdict by worst-severity: critical/high → `fail`, medium → `conditional`, low/none → `pass`. Legacy "Documentation readiness" three-state: PARTIAL → `conditional`, MISSING → `fail`, COMPLETE → `pass`.

### Persist + render

```bash
source "$(git rev-parse --show-toplevel)/.claude/hooks/_lib-audit-history.sh"

# Lowercase severity in the payload — the lib expects critical/high/medium/low/info.
payload=$(mktemp); cat > "$payload" <<'EOF'
{
  "schema_version": 1,
  "findings": [
    {"id": "D1", "severity": "high",   "status": "open", "summary": "README: unimplemented feature in present tense; npm run dev not in package.json"},
    {"id": "D2", "severity": "high",   "status": "open", "summary": "No docs/how-to/ dir; recipes scattered in Slack"},
    {"id": "D3", "severity": "high",   "status": "open", "summary": "Env vars not documented in README (12 in .env.example)"},
    {"id": "D5", "severity": "medium", "status": "open", "summary": "README references Express; code migrated to Fastify 3 months ago"}
  ]
}
EOF

# Body: per templates/audits/docs-audit.md (Diataxis quadrants + README + staleness)
body=$(mktemp); cat > "$body" <<'EOF'
... (filled-in body — Diataxis groupings + README quality + staleness + Recommended priority) ...
EOF

ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
audit_run_persist "<project-name>" "docs-audit" "$ts" "fail" 60 "$body" < "$payload"
rm -f "$payload" "$body"

audit_render_trend "<project-name>" "docs-audit" 5
```

### Opt-in commit

```bash
touch projects/<name>/audits/docs-audit/.audit-history-tracked
```

## Rules

1. **README is the minimum.** Every project needs one, and it must answer the four reader questions in proportion to the project's scope — not merely carry the headings. Step 1 is the bar; this rule is why it can't be skipped.
2. **Check for staleness, not just existence.** A README that exists but describes the wrong stack is worse than no README.
3. **Judge content, not headings.** Step 1 audits against [`.claude/rules/readme-quality.md`](../../rules/readme-quality.md). A section that exists but says nothing is a finding. Verify commands against the repo's real tooling and claimed features against the code — a plausible-sounding README is exactly what a fluent author produces.
4. **Scale to the project before reporting a gap.** A CLI tool has no evaluation section by design; a retrieval service without one is a high finding. Ask whether a section applies before reporting it missing — but treat a *silently omitted* absence (no tests, no CI) as a finding, since omission reads as capability.
5. **Diataxis is a lens, not a checklist.** Don't fail a project for missing all four quadrants — most projects start with tutorials + reference and add the rest over time.
6. **Auto-PASS for the ops repo itself.** ApexYard's own docs are governed by its own process — this skill is for managed projects.
7. **Always persist via the lib.** The persist step runs regardless of opt-in commit state.
8. **Severity vocabulary in the JSON is lowercase.** The lib expects `critical`/`high`/`medium`/`low`/`info`.

---

*Part of [ApexYard](https://github.com/me2resh/apexyard) — multi-project SDLC framework for Claude Code · MIT.*

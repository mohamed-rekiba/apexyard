# README Quality — Write for the Reader, Not the Repo

A README is the highest-traffic document any project has, and it is read by three people at once: someone deciding whether this project is relevant to them, someone trying to run it, and the author six months from now who has forgotten how it works. It is also the document an agent is most likely to produce badly, because a README *looks* easy — a title, a stack list, an install command — and looking finished is not the same as being useful.

This rule is the authoring standard. It is the README-side sibling of [`pr-quality.md`](pr-quality.md) § "Summary bullets — narrative quality": both say the same thing in different places — *a document whose reader has to go do archaeology has failed, no matter how tidy it looks.*

Shape to author against: `templates/project-readme.md`. Adopters override it at `<private_repo>/custom-templates/project-readme.md` (see [`templates/README.md`](../../templates/README.md) for the path-mirroring convention).

## The rule

**A README answers four questions, in this order. Everything else is arrangement.**

| # | Question | Sections that answer it |
|---|----------|-------------------------|
| 1 | **What is this?** | Title + one-sentence description, the problem, a demo |
| 2 | **Does it work?** | Evaluation, testing, monitoring |
| 3 | **Can I run it?** | Quickstart, configuration, deployment |
| 4 | **How was it built?** | Architecture, project structure, decisions and trade-offs, CI/CD |

Optionally closed by limitations and future work.

Concretely, when writing or revising a README:

- **Open with the user, the problem, and the solution — never the stack.** "Built with Next.js, tRPC and Postgres" is the most common first line in the wild and it tells a reader nothing about whether the project is for them. Use the shape *"{Project} is a {system type} that helps {specific user} do {task}."*
- **Put live links directly under the title**, above the prose. Someone who just wants to see it working should not have to scroll to find out they can.
- **Show it working without installation.** A live link, video, GIF, screenshot, or a worked input/output block — in that order of preference. Keep a static asset next to any live link, because hosted demos rot and a dead link is worse than no link.
- **Justify the claim that it works.** For anything with a quality dimension — retrieval, ranking, ML, AI features, parsers — name the dataset, the baseline, what changed, and the final numbers. Without this a reader can see output but cannot judge whether it is *reliable*.
- **Make the quickstart the shortest reliable path from clean machine to running app** — prerequisites, clone, install, configure, start services, run. Run it on a fresh clone before you write it down.
- **Separate required configuration from optional.** State plainly whether the app boots without the monitoring stack, the cloud account, the third-party API. This is the question every first-time reader has, and it is almost never answered.
- **Explain the consequential decisions, not every choice.** Use *"Chose X over Y because of constraint Z. The cost is A, accepted because B."* The technology matters far less than the visible reasoning.
- **Give diagrams a sentence.** A diagram shows what the components are; it rarely shows why each one exists. Write that line underneath.
- **Scale to the project.** A CLI tool needs no evaluation section. Proportionality is part of the standard, not an exception to it — a bloated README on a small project is its own failure.

## Two honesty rails (non-negotiable)

These are the rails because they are the two ways a README stops being merely unhelpful and starts being *wrong*:

1. **Present tense describes only what ships today.** Never write a planned capability as though it exists. Unbuilt things go under Future Work, and nowhere else. This is the single most damaging README failure an agent commits, because a confident feature list is indistinguishable from a true one until someone tries to use it.
2. **State absences; do not omit them.** No automated tests, no CI, no monitoring — write that plainly under the relevant section or Limitations. Deleting the section to tidy up converts a known gap into an implied capability. A reader cannot tell "not applicable" from "missing" unless you tell them.

## Anti-patterns

| Anti-pattern | Why it fails |
|--------------|-------------|
| **Stack list as description** | Names the tools, not the purpose. The reader still doesn't know what it does or who it's for. |
| **No demo** | Requiring a reader to clone and run before they can see anything loses most of them at the first command. |
| **No evaluation on a quality-sensitive project** | Turns a working system into an unverifiable demo. Output without measurement is a claim, not evidence. |
| **Untested setup commands** | The highest-cost defect in a README. Every reader hits it, and it is invisible to the author whose machine is already configured. |
| **Buried work** | Evaluation, experiments, prompts, and results that exist in the repo but aren't linked from the README effectively don't exist. |
| **Stale content** | Commands, screenshots, metrics, and deploy links that describe a previous version. A wrong README is worse than a thin one — it actively misleads. |
| **Planned features in present tense** | See rail 1. The reader cannot distinguish intent from reality. |
| **Wall of text** | Sections, commands, tables, and diagrams exist so a reader can scan. Undifferentiated prose forces linear reading of a reference document. |
| **`tree` dump as structure** | Complete output buries the handful of paths that actually aid navigation. Simplify and annotate. |
| **Undescriptive notebook names** | `notebook1.ipynb`, `final_v2.ipynb` — the reader cannot tell which one produced the reported numbers. |

## When NOT to reach for this

- **A README that already meets the bar.** Rewriting a good README into this template's exact section order is churn. The four questions are the standard; the headings are one way to arrange them.
- **Non-README docs.** A CONTRIBUTING, a runbook, an ADR, or a design doc has its own shape — several ship in `templates/`. This rule governs the front door only.
- **A deliberate stub, declared as one.** A repo three commits old can legitimately have a two-line README saying what it will become. That is honest; a *stub dressed as a finished README* is what the rails prohibit.
- **The operator explicitly asked for something else** — "just give me a one-paragraph readme, no ceremony" is a legitimate override. Respect it and say what was left out.

## Verify before publishing

An agent writing a README is working from a repository it has read, which makes it fluent — and fluency is exactly what makes invented commands plausible. Before publishing, check against the repo, not against your own draft:

- Every command appears in the project's actual tooling (`package.json` scripts, `Makefile`, `pyproject.toml`, CI workflow) and matches its real shape.
- Every environment variable named is one the code actually reads, and every variable the code requires is documented.
- Every file path, link, and badge resolves.
- Every capability described in present tense exists in the code today.
- Every reported metric traces to a result in the repo, and is current.

## Self-check before writing a README

```
[ ] Does the first sentence name the user and the problem — not the stack?
[ ] Can a reader see it working without installing anything?
[ ] If output quality is a question, are there real numbers and a dataset?
[ ] Did I run the quickstart on a clean checkout, in the shape I wrote it?
[ ] Is required configuration distinguishable from optional?
[ ] Is every present-tense capability actually shipped? (rail 1)
[ ] Are missing tests / CI / monitoring stated rather than omitted? (rail 2)
[ ] Are the consequential decisions explained with their trade-offs?
[ ] Is the length proportional to the project?
```

If the last two are unchecked the README is thin. If either rail is unchecked it is wrong, which is a different and worse problem — fix those first.

## Backstop

This rule is **primarily self-discipline**, the same shape as [`reporting-style.md`](reporting-style.md) and [`pr-quality.md`](pr-quality.md) § "Summary bullets". No hook can read prose quality, and no hook fires on "the agent is about to write a README" — `Write` to `README.md` is indistinguishable at the tool boundary from any other markdown write.

The one place this is checked at all is **`/docs-audit` step 1**, which audits an existing README against this standard and reports findings as `D1`. Even that is agent judgment working from a checklist, not a mechanical test — and it runs on demand, after the fact. It catches a bad README that already exists; it does not prevent one being written. Treat it as a review pass, not a gate.

The cost of following this rule is a longer first draft. The cost of skipping it is the failure the framework was reported for: READMEs that list technologies, ship a setup command nobody ran, and describe features that don't exist yet.

---

*Part of [ApexYard](https://github.com/me2resh/apexyard) — multi-project SDLC framework for Claude Code · MIT.*

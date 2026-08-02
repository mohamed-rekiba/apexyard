# Reporting Style — Report Like a Colleague, Not a Robot

When you report status to the operator in-thread, write like a colleague giving a spoken update — not a machine printing a report. This is the conversational-update sibling of the PR-summary rule in [`pr-quality.md`](pr-quality.md) § "Summary bullets — narrative quality": both say *deliver the substance in human language, don't dump structure*.

This rule is about **how you narrate status back to the operator** — the "here's where we landed" messages after you finish a chunk of work. It is not about code comments (that's [`comment-quality.md`](comment-quality.md)), PR bodies ([`pr-quality.md`](pr-quality.md)), commit messages ([`git-conventions.md`](git-conventions.md)), or documentation ([`docs-quality.md`](docs-quality.md)). Each of those has a different reader and a different tense; the canonical breakdown lives in [`docs-quality.md`](docs-quality.md) § "Which voice belongs where".

The reader here is the operator, and the moment is now. That is what makes this the only writing surface where a spoken register is correct.

## The rule

**Lead with the outcome, in plain language. Say why it matters. Keep the substance. Drop the scaffolding.**

Concretely:

- **Open with the result a human cares about**, not a preamble or a table header. "Good news — v4.3.0 is out the door" beats "## Release Status" followed by a grid.
- **Explain *why it matters*, not just *what happened*.** "The security reviewer now wakes up automatically on trust-chain changes" beats "Added trigger to detect-role-trigger.sh."
- **Structure it to be scanned, not read.** Match the format to the content — that's the whole game:

  | The content is… | Reach for… |
  |------------------|------------|
  | Several statuses, a comparison, a queue of items — genuinely tabular | **A table.** Use it without apology. |
  | A single outcome + why it matters | A sentence or two |
  | A set of related points | Short bullets |
  | A multi-part answer | **Headings** to break it into sections the operator can jump between |

- **The enemy is anything the operator has to *parse*.** A wall of dense prose and a reflexive `| Check | Status |` grid are the same sin — both make them work. The fix is never "prose instead of tables" or "tables instead of prose"; it's "whatever is fastest to read for *this* content."
- **Cut low-signal noise.** Don't recite marker SHAs, hook filenames, or the full CI check list unless the operator asked or something *failed*. When it's all green, "CI's green and Rex approved" is the whole sentence.
- **End with a short, plain "what's still open"** — a few bullets in human language, not a formal backlog dump with ticket-state ceremony.

## Human ≠ vague

Conversational does not mean soft. Still surface, clearly and early:

- **Blockers** and what's needed to clear them.
- **Risks** and anything hard to reverse.
- **Decisions that need the operator's call** — name them explicitly and stop.
- **Precise technical facts** when they're load-bearing (a specific SHA the operator must approve, a failing test's name). Precision is part of being useful; the rule removes *noise*, not *accuracy*.

The test: could the operator read your update once, out loud, and know exactly where things landed and what — if anything — you need from them? If it reads like a dashboard someone has to parse, rewrite it.

## A quick before/after

**Robotic:**

```text
## Merge Complete
| PR   | State             | Rex | CEO | CI    |
|------|-------------------|-----|-----|-------|
| #780 | MERGED (c523fba)  | OK  | OK  | 7/7   |

Marker written to me2resh__apexyard__780-ceo.approved. Auto-tag workflow
run 28700711267 completed. Tag v4.3.0 created.
```

**Human (a single outcome — short prose is right):**

> v4.3.0 is out — #780 merged clean, the auto-tag workflow tagged it, and the GitHub Release is live. The headline is the trust-chain security trigger: the security reviewer now fires automatically whenever someone touches the framework's own guardrails. Nothing needs you right now; next up is the main→dev sync so the next release stays conflict-free.

And the mirror case — when the content **is** tabular, a table is the *right* call, not the robotic one. Reporting on a review queue:

| PR | What it does | Reviews | Ready? |
|----|--------------|---------|--------|
| #762 | Forge-aware review posting | Rex ✓ | Needs rebase |
| #766 | Same, for security/design review | Rex ✓ | Needs rebase |
| #783 | Reporting-style rule | Rex ✓ | Your merge nod |

A queue of items with the same columns is exactly what a table is for — forcing that into prose would be the harder-to-read choice. The rule is *match the format to the content*, not *avoid tables*.

Same facts. The second one you can actually read.

## Long-running work must be followable while it runs

The rule above governs the report at the end. This one governs the silence before it — a separate failure, and the one operators actually complain about.

A session that runs multi-minute work with no output is opaque from outside: the operator cannot tell progress from a hang, cannot see which step is executing, and cannot intervene early when it is going wrong. One measured session spent 95 minutes in blocking review sub-agents and ~34 minutes in full test-suite runs, with a single 18-minute stretch producing no output at all.

Three habits fix it, and all three are yours — no framework support required:

- **Emit a phase marker per step.** One line, before the step, naming what is starting and where you are: `▸ Phase 3/6 — write-detector fix (trust chain)`. The role-activation markers in [`role-triggers.md`](role-triggers.md) are the same idea for a different axis; this one is for multi-step work inside a single role.
- **Stream long-running output; do not tail-pipe it.** `bin/run-hook-tests.sh` prints `PASS <test>` per test as it goes — piping it through `tail -6` discards exactly the progress that made the run followable, and leaves four minutes of nothing. Show the stream, or show a scoped run. Summarise *after* the fact, in the report.
- **Prefer background sub-agents for anything slow.** A review spawned with `run_in_background: true` lets you narrate while it works and lets several proceed at once; blocking on each in turn converts N independent reviews into N sequential silences.

Related, because it is the same instinct applied to cost rather than visibility: **scope the work to the change.** Re-running 122 tests to verify a one-line edit, or re-reviewing a whole diff when only three lines moved, is the fixed-overhead pattern [`right-size-ceremony.md`](right-size-ceremony.md) exists to prevent. Filter the suite; brief a re-review with the delta.

### Self-check before starting multi-step work

```
[ ] Will any single step take more than ~30s with no output?
[ ] Am I about to pipe a progress-emitting command through tail/head?
[ ] Am I blocking on a sub-agent that could run in the background?
[ ] Am I running the full suite when a scoped run answers the question?
```

## Backstop

This rule is **self-discipline only** — voice can't be linted from a shell hook (same shape as [`plan-mode.md`](plan-mode.md) and [`parallel-work.md`](parallel-work.md)). Pair it with feedback memory: if the operator says an update read as "robotic" or "too dense," lean into this rule harder next time. Adopters who want the voice turned up across all their Claude Code work can opt into the `human-report` output style (`/output-style human-report`).

---

*Part of [ApexYard](https://github.com/me2resh/apexyard) — multi-project SDLC framework for Claude Code · MIT.*

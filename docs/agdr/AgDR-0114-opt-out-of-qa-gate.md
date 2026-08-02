# Opt this fork out of the mandatory QA stop

> In the context of a solo-operator fork where the author and the verifier are the same person, facing a QA gate whose ceremony exceeded what it returned, I decided to set `ticket.qa_label` to `""` and close tickets on merge via the host's native auto-close, to achieve a merge flow that finishes, accepting that nobody independently confirms merged code does what its ticket claimed.

## Context

Gate 6 makes QA a mandatory stop: a merged PR moves its ticket to QA, and a QA Engineer closes it only after verifying every acceptance criterion. That is why PR bodies use `Refs #N` rather than `Closes #N` — `Closes` would let the host auto-close on merge and skip verification.

me2resh/apexyard#3 made the transition real for the first time (it was previously documented and watched, but never executed). Immediately after it shipped, the operator asked why their tickets were still open, reviewed what verification actually required — 15 mechanically-checkable criteria across two tickets — and concluded the gate was not earning its keep on this fork.

The decisive fact is structural, not preference: **the gate's value comes from the author and the verifier being different people.** On this fork they are the same. A verifier re-checking their own work is a genuine second pass, but it is not independence, and it is not what the gate was designed to buy.

## Options Considered

| Option | Pros | Cons |
|--------|------|------|
| **A.** Keep the gate, verify each ticket | Preserves the framework default; the criteria really are checkable | Full ceremony for a check the same person performs on their own work; the operator has already declined it twice |
| **B.** Set `qa_label: ""` + `Closes #N` in PR bodies | No new code, no trust-chain surface; uses the host's native auto-close; the opt-out already exists (shipped in #3) | Relies on PR bodies actually carrying `Closes` — a convention, not a mechanism |
| **C.** Add `tracker_issue_close` + an `on_merge: close` config | Mechanical rather than conventional | Adds an issue-*closing* capability to the trust chain — precisely what AgDR-0113 scoped **out** of `tracker_label_add`, and it would run unattended straight after an irreversible merge |
| **D.** Delete Gate 6 from the framework | Simplest to reason about | Wrong for every team adopter; the gate is correct where author ≠ verifier |

## Decision

Chosen: **Option B**.

It reaches the operator's goal with **zero new code and zero trust-chain surface**. Option C was the tempting "do it properly" answer and is the wrong trade: AgDR-0113 deliberately bounded `tracker_label_add` to add-only *because* its caller runs unattended after an irreversible merge, and adding a close capability to that same path would reopen exactly the blast radius that boundary exists to contain. The host already closes issues natively; the framework does not need the ability.

Option D was rejected because this is a **fork-local** call. The gate stays the shipped default in `project-config.defaults.json`, and `workflow-gates.md` / `sdlc.md` now document the opt-out rather than being quietly contradicted by it. A framework asserting a mandatory gate that its own reference fork silently ignores is the documentation-vs-reality failure this repo has already had to correct more than once.

## Consequences

- **Nobody checks that merged code does what its ticket said.** This is the real cost and it should not be softened. Code review (Rex) and, on trust-chain diffs, the Security Auditor still run, and in this fork's short history they have caught substantially more than QA would have — a transition that was inert twice, a data-loss path, a vacuous test assertion. But those are code-level checks; "did we build what the ticket asked for" is now unverified by anyone but the author.
- **Acceptance criteria become documentation rather than a gate.** Still worth writing — they shaped every ticket in this fork and caught scope drift during authoring — but nothing now confirms them post-merge.
- **The convention is the weak link.** Option B depends on PR bodies carrying `Closes #N`. Nothing enforces it (`verify-commit-refs.sh` accepts both forms and only checks the issue exists), so a body written with `Refs` will leave its ticket open with no label and no QA state — silently inconsistent rather than wrong. If that recurs, the fix is a PR-body check, not Option C.
- **Reversible in one line.** Removing `ticket.qa_label` from `.claude/project-config.json` restores the default. Nothing else in this change is lossy.
- Step 8a now resolves referenced tickets *before* the label guard, so step 11 still clears `current-ticket` when the transition is disabled (previously the whole block was skipped, taking the cleanup with it — noted as N3 in the PR #4 review).

## Artifacts

- Ticket: mohamed-rekiba/apexyard#5
- Supersedes the gate's application on this fork only; AgDR-0113 (which built the transition) remains valid and its reasoning unchanged.

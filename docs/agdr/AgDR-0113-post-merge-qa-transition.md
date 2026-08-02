# Perform the post-merge QA transition via a trust-chain label helper

> In the context of a merge completing through `/approve-merge`, facing a documented QA transition that nothing ever executed, I decided to add an add-only `tracker_label_add` to the trust chain and teach the role-trigger hook to recognise it, to achieve an actually-firing QA gate, accepting a new function in `.claude/hooks/**` and a second wrapper-shape matcher in `settings.json`. The trust-chain write permissions needed to implement it are **deliberately kept out of the shipped tree** — see "The permissions grant" below.

## Context

`workflow-gates.md` Gate 6 states that a merged PR moves its ticket to **QA**, not Done. `sdlc.md` explains this is why PR bodies use `Refs #N` rather than `Closes #N` — `Closes` would let the host auto-close on merge and skip acceptance-criteria verification. `detect-role-trigger.sh` watches for the `qa` label in order to auto-fire the QA Engineer.

Nothing ever applied that label. `/approve-merge`'s post-merge steps were a board-card move (opt-in, a no-op for most adopters) and an optional child-issue closure. The state machine had a transition no component performed, so the QA role could not fire from a merge and merged tickets sat in limbo indefinitely.

Two constraints shaped the fix:

1. The framework has spent several releases making tracker interactions **forge-agnostic** (`tracker_create` #670, `tracker_review_submit` #758, `tracker_pr_merge` #759). A new interaction that hardcodes `gh` would regress that.
2. `detect-role-trigger.sh` recognises label transitions by **pattern-matching raw Bash command text** for `gh issue edit`. Any forge-agnostic wrapper is invisible to it — the CLI string lives inside sourced library code, not in the command the hook sees. This is the identical problem `tracker_pr_merge` hit, and it is why `settings.json` already carries a dedicated `Bash(tracker_pr_merge *)` matcher.

Constraint 2 is the one that makes this decision material rather than routine: satisfying constraint 1 *alone* produces a change that is completely inert.

## Options Considered

| Option | Pros | Cons |
|--------|------|------|
| **A.** Call `gh issue edit --add-label` inline in the skill | No trust-chain change; the existing role trigger fires unmodified | Hardcodes GitHub, regressing the forge-agnostic arc; a GitLab adopter silently gets no QA transition |
| **B.** Add `tracker_label_add` only | Forge-agnostic; mirrors an established adapter shape | **Inert** — the role trigger never fires, so the QA Engineer never activates and the whole change does nothing |
| **C.** Add `tracker_label_add` **and** teach the trigger + `settings.json` to recognise the wrapper | Forge-agnostic *and* actually fires; mirrors the `tracker_pr_merge` precedent exactly | Touches two trust-chain files, including `settings.json`; widens the hook's matcher surface |
| **D.** Close the ticket on merge instead | Simplest; matches the naive request | Bypasses Gate 6, which the framework calls mandatory; makes the `Refs`-over-`Closes` convention pointless |

## Decision

Chosen: **Option C**, because it is the only option that is both forge-agnostic and non-inert. Option B is the trap worth recording — it looks correct, passes a naive test, and does nothing, which is exactly how the original gap survived so long.

Option D was explicitly rejected on the framework's own terms. The operator's literal request was "close the issue when the PR merges"; closing would defeat the gate that the `Refs`/`Closes` split exists to protect. Applying the label *starts* QA rather than skipping it, and the ticket still closes — after verification.

Two boundaries constrain the trust-chain surface this adds:

- **`tracker_label_add` is add-only.** It can attach a label and perform no other mutation — no close, reopen, comment, or assign. Its caller runs immediately after an irreversible merge with no further human confirmation, so the blast radius has to stay small. A future need to close a ticket gets its own reviewed function with its own confirmation story, not a parameter widening this one.
- **The trigger's matcher stays narrow.** It recognises the wrapper's positional form only, and keeps the existing rule that `gh issue create --label qa` (a *new* ticket) does not fire the trigger — the semantic is a transition, not an initial state.

## The permissions grant — and why it does NOT ship

Implementing Option C required editing `.claude/hooks/detect-role-trigger.sh` and `.claude/settings.json`. The auto-mode classifier blocked both — correctly, since those files *are* the trust chain, and a model silently rewriting the hook that decides whether security gates fire is exactly what that control exists to prevent.

Unblocking needs `Edit`/`Write` allow rules for those paths. The question was **where they live**, and the answer went through one reversal worth recording.

The rules were first committed to the tracked `.claude/settings.json`. Hakim's review graded that **HIGH** and it was moved to a gitignored `.claude/settings.local.json` before merge. Nothing about the grant ships to adopters; `origin/main` carries no `permissions` block, and this PR does not add one.

Why the tracked location was wrong, stated plainly so nobody re-proposes it:

- **It is not a personal setting there.** Every adopter of the fork would inherit standing permission for the agent to write to the trust chain with no per-edit prompt, having never seen this record.
- **It is self-amplifying.** `Write(.claude/settings.json)` permits rewriting `permissions.allow` itself, so the grant contains the capability to redefine its own limits. `Write(.claude/hooks/**)` *creates* files, not only edits them — and `settings.json` already wires `SessionStart`, so create-a-script → wire-it → unprompted execution on the next session.
- **The remaining controls were fewer than they looked — and this record got that wrong twice.** The first draft named three: the per-PR human merge approval, the merge gate's SHA-matched markers, and this security review. The second draft cut it to one, keeping the human approval. Both were too generous, and the honest count is nearer **zero framework-internal controls**:
  - The **merge gate** is `block-unreviewed-merge.sh`, under `.claude/hooks/**`. A control the grant makes writable is not independent of it.
  - The **security review** is circular for the same reason: `detect-role-trigger.sh`, which auto-fires it, is inside the globs too. It is also periodic rather than preventive.
  - The **human approval** is the subtlest. `disable-model-invocation: true` locks the *skill* — and `.claude/skills/**` is genuinely outside the globs — but the merge itself is a Bash command, gated by the hook above. Locking the front door while the grant covers the lock is not a control.
  - Nothing server-side backs any of it: `main` on this fork has **no branch protection** (`gh api .../protection` → 404).

  This strengthens the conclusion rather than weakening it, which is precisely why it belongs here. A decision record that overstates its own residual safety is the failure mode this framework has already had to correct once, in `right-size-ceremony.md`'s claim about a token meter it did not ship.

The decisive argument is not the severity but the absence of any upside: the tracked location buys nothing the gitignored one doesn't. Both unblock identically. Only one propagates.

## Consequences

- The QA Engineer role now auto-fires on merge, which is the first time Gate 6's entry condition is mechanically produced rather than assumed.
- `settings.json` gains a second wrapper-shape matcher. This is the ongoing cost of the forge-agnostic wrapper pattern: every wrapper that a hook needs to observe requires its own matcher, because hooks match command text and wrappers hide their CLI. Recorded here so the next wrapper author expects it.
- Adopters who do not want the transition set `ticket.qa_label` to `""`. This must be read with `config_get`, **not** `config_get_or` — the latter substitutes its fallback on any empty value, making the opt-out unexpressible.
- Post-merge steps are best-effort by contract: the merge is already irreversible, so a labelling or cleanup failure warns but never reports the merge as failed. They are additionally gated on the merge having actually succeeded, so a gate-blocked merge does not label a ticket QA or delete its still-valid approval markers.

## Artifacts

- Ticket: mohamed-rekiba/apexyard#3
- PR: mohamed-rekiba/apexyard#4
- Prior art: `tracker_pr_merge` (#759) — the same wrapper-invisibility problem and the matcher pattern this follows

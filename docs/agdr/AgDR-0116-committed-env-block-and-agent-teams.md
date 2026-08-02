# A committed `env` block in `settings.json`, and enabling agent teams

> In the context of committing two operator settings to the tracked `.claude/settings.json`, facing a security review finding that the `env` block is an unreviewed injection surface into every hook process, I decided to commit both keys and record `env` as a trust-chain surface requiring security review, rather than adding a mechanical guard, to achieve an honest record of a real gap, accepting that nothing mechanically prevents a later `env` entry from disabling every gate in the framework.

## Context

Two keys were added to the tracked `.claude/settings.json`:

```json
"model": "opus[1m]",
"env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }
```

The file is tracked, so both apply to anyone working in this fork. It is also trust chain: `role-triggers.md` lists `.claude/settings.json` as the matcher wiring that decides whether a gate fires at all, which auto-fires the Security Auditor.

That review verified the `hooks` object is **byte-identical** between base and HEAD in both canonical and original key order — 4 events, 8 matcher groups, 77 command entries, 49 unique scripts, none added, removed, or altered. No `disableAllHooks`, no `permissions`. The two added keys are inert.

**The finding is not either key. It is the precedent of a committed `env` block**, because `env` exports into every shell the harness spawns, hook processes included, and the framework's enforcement reads its behaviour from the environment:

- **No hook pins an absolute binary path.** Verified across all 67 non-test scripts in `.claude/hooks/`: zero matches for `/usr/bin/gh`, `/usr/bin/jq`, `/usr/bin/git` or any absolute form. Every invocation is PATH-resolved, so a single `PATH` entry here substitutes every forge query and SHA comparison the merge gates depend on.

  *No per-binary count is given deliberately.* Three careful attempts produced three different answers for `gh` (16, 19, and a ceiling of 18) and for `git` (39, 50, 53), because the figure depends on the denominator — all 67 scripts, or the 49 wired into `settings.json` — and on whether comment lines count. An earlier draft of this record cited 23 / 42 / 39, of which two were wrong in *opposite* directions. The structural claim is what the decision rests on, it is unambiguous, and it reproduces:

  ```bash
  grep -rlE '/(usr/)?(local/)?bin/(gh|jq|git)[[:space:]]' .claude/hooks/*.sh   # → no matches
  ```

- **`APEXYARD_OPS_PIN_DIR`** would misdirect `MARKER_HOME` for all three marker-reading merge gates. The pin validates only against a presence-only, forgeable `.apexyard-fork` anchor.
- **`APEXYARD_ALLOW_*`** variables disable blocking gates with a stderr warning and nothing else.
- **No hook inspects `settings.json` content.** The trigger that summoned the review is a *role activation*, not a mechanical check. A human noticing the diff is the only control.

Compounding all of it: this fork has **GitHub Actions disabled** — zero workflow runs, ever — so nothing validates any of this server-side.

On agent teams specifically, the review was deliberately deflationary and correct to be. The marker-forgery risk it appears to raise is **already unenforced**: `warn-review-marker-write.sh` has been advisory since #1026 ([AgDR-0111](AgDR-0111-marker-gate-plain-advisory.md)), so a build agent can write `*-rex.approved` today regardless of teams. Teammates load the same hooks and inherit the same gates, so no teammate can do what its spawner is blocked from. What changes is smaller: attribution visibility, plus one concrete and **unverified** risk — `pin-ops-root.sh` keys its pin to `CLAUDE_CODE_SESSION_ID`, so teammate sessions with distinct IDs that skip `SessionStart` would fall back to walk-up resolution, which is the marker-misplacement failure the pin exists to prevent.

## Options Considered

| Option | Pros | Cons |
|--------|------|------|
| Don't commit; keep both in `settings.local.json` | No new tracked surface; no adopter-visible change | Hides a real configuration choice from anyone else using the fork, and the operator explicitly asked for them to be committed |
| **Commit both, record `env` as a reviewed trust-chain surface (CHOSEN)** | Honest and visible; the security review that fires on this path already produced the analysis; the gap is written down where the next reader meets it | Enforcement is a human reading a diff — the weakest control in the framework |
| Commit, and add a hook that inspects `settings.json` for dangerous `env` keys | Mechanical rather than advisory | A hook wired *inside* the file it validates cannot run if that file fails to parse. Deferred, not dismissed — it wants its own ticket and a denylist that will not rot |
| Pin absolute paths for `gh` / `jq` / `git` across 49 hooks | Closes the sharpest vector — a hostile `PATH` | Large, cross-cutting, and breaks portability across macOS / Linux / CI where these live in different places. Deferred |
| Don't enable agent teams | Nothing experimental in the trust chain | Gives up parallel review, which this framework benefits from unusually: each reviewer writes an independent marker, so Rex and Hakim genuinely run concurrently |

## Decision

Chosen: **commit both keys, and record `env` in `.claude/settings.json` as a trust-chain surface that requires security review on every change**, because the honest position is that this is currently governed by review rather than by a gate, and saying so is worth more than a guard that cannot cover the case that matters.

Agent teams is enabled deliberately. It was exercised while producing this change: two teammates ran in parallel on the analysis and messaged each other directly. One caveat is worth recording for anyone using it — **`SendMessage` is a deferred tool**, so a teammate must load its schema via `ToolSearch` before calling it, or the call fails with a validation error. Delivery is a queue with no read receipt, not a conversation.

## Consequences

- **`env` is now a reviewed surface.** Any future change to it in `.claude/settings.json` is trust chain and takes the Heavy path per [`right-size-ceremony.md`](../../.claude/rules/right-size-ceremony.md) rail 1, no matter how small the diff. A one-line `env` addition is exactly where the chain is wanted.
- **The gap is documented, not closed.** Nothing mechanically prevents a later `PATH` entry from substituting `gh` for every merge gate. Anyone relying on those gates should know that.
- **Two follow-ups are deferred with their reasons**: a `settings.json` content inspector (blocked on the bootstrap problem — it cannot validate the file it lives in), and absolute-path pinning for `gh` / `jq` / `git` (blocked on portability).
- **One half-verified risk is written down rather than guessed at.** The code path is confirmed: `pin-ops-root.sh` keys its pin to `CLAUDE_CODE_SESSION_ID`, and a session without that pin falls back to walk-up ops-root resolution — the marker-misplacement failure the pin exists to prevent. What remains genuinely open is harness behaviour: whether teammates receive distinct session IDs, and whether they run `SessionStart` at all. Cheap to check; not yet checked.
- **Whether the harness fails open or closed on a malformed `settings.json` is unknown.** Determining it meant corrupting the file, which the review declined to do. The structural point stands either way: the file cannot validate itself.
- **`model: "opus[1m]"` is purely operational** — no security consequence, stated so it is not mistaken for one.

## Artifacts

- PR: mohamed-rekiba/apexyard#20 — security review by Hakim, verdict APPROVED with two MEDIUM advisories, both recorded here
- Related: [AgDR-0111](AgDR-0111-marker-gate-plain-advisory.md) — why marker-write enforcement is advisory, which is why agent teams changes less than it appears to
- Related: mohamed-rekiba/apexyard#16 — `test_block_merge_on_red_ci.sh` fails on this host, **closed** (blocking a merge it should allow), the safe direction; a merge gate with a failing test and no CI is running unwatched

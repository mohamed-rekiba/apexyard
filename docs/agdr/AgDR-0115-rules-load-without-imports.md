# Rules load without `@` imports; `CLAUDE.md` carries triggers, not availability

> In the context of a session paying ~54k tokens before any work starts, facing the discovery that `CLAUDE.md`'s `@.claude/rules/*.md` imports do nothing because the harness loads that directory regardless, I decided to drop the redundant rule imports, un-import the two `workflows/` docs that genuinely do cost context, and replace the restated rule bullets with a trigger index, to achieve a 33,975-byte cut that is measured rather than assumed, accepting that `CLAUDE.md` no longer controls rule availability at all and that six tests had to stop asserting a mechanism that was never doing anything.

## Context

`CLAUDE.md` plus its imports came to 216,689 bytes — roughly 54k tokens loaded before the operator types anything. The obvious lever looked like the `@` import list: 17 rule files, 156,222 bytes.

That lever does not exist. **Claude Code loads every `.claude/rules/*.md` file whether or not `CLAUDE.md` imports it.**

Measured, not inferred. Disabling the `plan-mode` import and asking a **fresh session** (`claude -p`, tools forbidden) what it had loaded:

| File | `@` import | Loaded? |
|---|---|---|
| `.claude/rules/plan-mode.md` | disabled | **yes** |
| `.claude/rules/parallel-work.md` | never had one | **yes** |
| `workflows/sdlc.md` | disabled | **no** |
| `templates/agdr.md` | kept (control) | **yes** |

`rules in context: 22` in every probe. The independent review reproduced this against both `main` and the PR head, and added the `templates/agdr.md` positive control — a non-rules file whose import is retained. It still loads, which proves the probe can see imported files and that the two `workflows/` absences are real rather than an artifact of the method.

Two things follow. Un-importing a rule file saves nothing, so the original plan for me2resh/apexyard#14 — nine rules off the list, 73,263 bytes — would have shipped a no-op and reported a ~20k token/session saving that did not exist. And files **outside** `.claude/rules/` load only via `@`, which is where the real cost was sitting: `workflows/sdlc.md` at 18,508 bytes is larger than `CLAUDE.md` itself.

A trap worth recording, because it nearly produced the wrong answer: **a subagent cannot measure this.** One reported all three disabled imports still loaded, because it inherits the parent session's already-assembled instructions and confirms whatever the session started with. Only a fresh top-level session sees the change.

The five rules that were never imported — `workflow-gates`, `pr-quality`, `leak-protection`, `parallel-work`, `code-standards` — have been loading this whole time. Nobody noticed, which is why the belief that imports were load-bearing survived as long as it did.

## Options Considered

| Option | Pros | Cons |
|--------|------|------|
| Keep the imports, change nothing | Zero risk; no test churn | Preserves ~34k bytes/session of genuine waste and leaves three documents asserting a mechanism that does not exist |
| Drop the rule imports only | Honest about the no-op | Saves **nothing**, because that is precisely the point — pure churn with no benefit |
| **Drop rule imports, un-import the two `workflows/` docs, replace restated bullets with a trigger index (CHOSEN)** | 33,975 bytes measured; `CLAUDE.md` stops duplicating text already in context; the two large docs become read-on-demand at the boundary where they matter | Rule availability is now entirely implicit; the SDLC and code-review docs must be `Read` deliberately; six tests changed |
| Also cut the 66-row skill table (7,551 further bytes) | The harness already injects the same roster from `SKILL.md` frontmatter | Violates AgDR-0044's operator-prescribed constraint that every skill stays catalogued in `CLAUDE.md`. **Rejected** — reversing an operator constraint is its own decision, not a line item in a chore PR |
| Shorten or delete rule files | The only remaining lever on the 185,623 bytes | Much larger blast radius; deletes governance rather than duplication. Deferred |

## Decision

Chosen: **drop the redundant rule imports, un-import `workflows/sdlc.md` and `workflows/code-review.md`, and replace the restated `### Quality Rules` bullets with a trigger index**, because the only bytes that can be saved are the ones an `@` import actually controls, plus the text physically inside `CLAUDE.md`.

The division of labour this establishes:

- **Availability** is the harness's job. A rule is live because the file exists in `.claude/rules/`. Adding a file is sufficient; nothing needs wiring.
- **`CLAUDE.md`'s job for rules is to say _when_ each applies** — the trigger index — not to make it available. This is the part that can genuinely go missing, so it is what the tests now assert.
- **Files outside `.claude/rules/` still need `@`**, and each one should earn a permanent seat. `sdlc.md` and `code-review.md` do not: both are consulted at a boundary (crossing a phase, reviewing by hand), not on every turn. `templates/agdr.md` keeps its import at 1,039 bytes because it is filled in during a decision made in the moment.

The workflow-gates table stays inline in `CLAUDE.md` precisely because it applies continuously, which is the distinction being drawn.

## Consequences

- **~8.5k tokens returned per session**, every session, on every fork.
- **Six test files stopped asserting `@` imports** and now assert that `CLAUDE.md`'s trigger index names the rule. The assertion is scoped to the index section by an `awk` helper — an unscoped grep also matches the TEMPLATES table and passes even after the trigger is deleted, which was caught only because a negative test came back silent instead of failing.
- **Three documents were corrected**, most sharply `docs/architecture/apexyard-container.md`, which said *"Without that import chain, rules are orphaned prose"* about an arrow it called the single most important one. That arrow does not exist.
- **A new failure mode replaces the old one.** Previously a rule could be orphaned by a missing import — impossible now. Instead a rule can be *available but untriggered*: loaded, and nothing tells the agent when it applies. `code-standards.md` is arguably already in that state.
- **The `@` mechanism is now rare enough to be surprising.** One import remains. A future contributor adding a `workflows/` doc will not find a pattern to copy, so the reason is written into `CLAUDE.md` itself rather than left to this record.
- **The finding that outlives the change: 185,623 bytes of rule files load unconditionally, with no import-list lever at all.** The only ways down are shorter rules or fewer rules. Two rules added in one recent session put ~27,189 bytes onto every session permanently, and there is no opting out of them. This is now the framework's main context cost and deserves its own ticket.

## Artifacts

- PR: mohamed-rekiba/apexyard#20 — `chore(#14): cut 34k bytes from every session's starting context`
- Ticket: mohamed-rekiba/apexyard#14
- Supersedes the import-chain claims in `docs/architecture/apexyard-container.md` and `docs/harnesses/claude-code.md`
- Related: [AgDR-0044](AgDR-0044-token-efficiency-wave-1.md) — Wave 1 compression, whose operator constraint blocked the skill-table cut

# Comment Quality — Explain the Why and the Trap

A comment is the only part of a codebase nothing checks. Tests catch wrong code, the type checker catches wrong types, review catches wrong logic — a wrong comment sails through all three and is then believed, because a reader who could already tell it was wrong would not have needed it. That asymmetry is the whole reason comments need a standard: the ones that earn their place are extremely valuable, and the ones that do not are worse than silence.

This rule expands the one-line standard in [`code-standards.md`](code-standards.md) — *comments explain why, not what*. The voice for a comment is present tense, describing the code as it stands; the full surface-by-surface breakdown is in [`docs-quality.md`](docs-quality.md) § "Which voice belongs where".

## The rule

**Comment what the code cannot say: the why, the constraint, and the trap. Never restate the what.**

The code already states what happens, and it is authoritative in a way a comment can never be. A comment earns its place only by carrying information that is not recoverable from reading the lines below it.

### The four comments that earn their place

- **Why this, and not the obvious thing.** Name the approach the next reader will reach for, and why it fails here. This is the single highest-value comment in any codebase, because without it the "simplification" gets made, the tests still pass, and the original problem comes back months later.

  ```bash
  # Check emptiness BEFORE expanding. Under `set -u`, bash 3.2 (still the
  # system bash on macOS) errors on "${arr[@]}" when arr is empty, so the
  # no-match path must exit before the assignment, not after it.
  ```

- **The trap.** A portability quirk, an ordering constraint, a footgun in a dependency. BSD `sed` silently ignores `\b` where GNU `sed` honours it, so a word-boundary match that passes in CI fails on a maintainer's laptop with no error — a reader has no way to derive that from the code, and every reader who touches the line needs it.

- **The deliberate omission.** The check that is intentionally *not* there, so the next reader does not helpfully add it. `require-agdr-for-arch-changes.sh` deliberately leaves a bare `infrastructure/` directory out of its trigger globs, because the word is ambiguous between infrastructure-as-code and ordinary library code and matching it produced false positives on `docs/infrastructure/notes.md`. Without the comment, that omission reads as an oversight.

- **The fail direction.** For any guard, gate, or validator: which way it fails when it cannot decide, and that this is the intended direction. `require-active-ticket.sh`'s out-of-governance exemption carries an explicit fail-closed note precisely because an ambiguous write target must fall through to the gate rather than past it, and that intent is invisible in the control flow.

### And the rest

- **Prefer a better name over a comment for the *what*.** If the comment exists to explain what a variable holds, rename the variable. Then keep the comment for the why, which no name can carry.
- **Put the comment where the reader hits the problem** — immediately above the line that surprises, not in a header block thirty lines away that nobody scrolls back to.
- **File headers state purpose, usage, and the non-obvious contract.** What this file is for, how it is invoked, what it guarantees, what it deliberately does not. Not a change log.
- **Length is earned, not budgeted.** A twelve-line comment above four lines of code is correct when those four lines encode a decision that took an afternoon. A one-line comment above a hundred lines of obvious code is usually noise.

## Two rails (non-negotiable)

1. **A comment describes current behaviour.** When you change the code under a comment, change the comment in the same edit — not in a follow-up, because there is no mechanism that will remind you. A stale comment is strictly worse than no comment: it is read as authoritative, it contradicts the code silently, and it survives review because reviewers read diffs and the comment is not in the diff.

2. **Reference history only when the past *is* the reason.** A comment saying "this used to be a for-loop" is noise — that is what `git log` is for, and the reader is not asking. A comment saying that a check is deliberately advisory *because* a previous blocking version pattern-matched command text and failed in both directions at once is load-bearing: it stops the next reader from re-tightening it and re-earning the same failure. The test is whether a reader who does not know the history would make a mistake without it.

   When history does earn its place: **state the current behaviour first, then the reason.** "This is advisory; it was blocking until the text-matching approach proved unsound" reads correctly. "Since #1026 this is advisory" makes the reader reconstruct the present from the past.

## Anti-patterns

| Anti-pattern | Why it fails |
|--------------|-------------|
| **Restating the code** — `i++  // increment i` | Adds a second thing to keep in sync and says nothing. |
| **Commented-out code** | The reader cannot tell dead from temporarily-disabled, so nobody ever deletes it. Git holds it; delete it. |
| **TODO with no owner and no condition** | Never actionable, becomes wallpaper, and eventually reads as a known-broken marker nobody can act on. Write what would have to be true to do it. |
| **A bare ticket number** — `# see #412` | The reader has to leave the file, load a tracker, and read a thread to learn one sentence. Write the sentence; keep the link. |
| **Stale comment** | Rail 1. Believed, wrong, and invisible in review. |
| **Change log in a file header** | Duplicates `git log`, drifts from it immediately, and pushes the actual contract below the fold. |
| **Comment as apology** — "hacky but works" | Tells the reader something is wrong and nothing about what. Either say why it must be this way, or fix it. |
| **Section banners over trivial spans** — `// ===== HELPERS =====` above two functions | Structure theatre. Reach for it when a file genuinely has navigable regions. |
| **Doc comment restating the signature** | `@param userId The user ID` costs a line and teaches nothing. Document the constraint: what makes it invalid, what happens when it is. |
| **Explaining a workaround without its exit condition** | The workaround outlives the bug it works around. Say what has to change for it to go. |

## When NOT to reach for this

- **Genuinely obvious code.** Most lines need no comment, and a codebase commented uniformly is one where the important comments are camouflaged.
- **Generated files.** Do not hand-annotate output that will be regenerated.
- **Tests whose names already carry the intent.** `it("rejects a merge when the marker SHA does not match HEAD")` needs no comment above it. A comment explaining *why the case matters* still can.
- **The operator asked for uncommented code.** A legitimate override — say what you left out.

## Verify before committing

- Every comment matches the code directly below it, as of this edit.
- Every issue, AgDR, or file reference in a comment resolves, and still says what the comment claims.
- Every claim about another file's behaviour is still true — renames and refactors break these silently.
- No comment describes behaviour that is planned rather than present.

## Self-check before committing

```
[ ] Does each comment say something the code below cannot?
[ ] Did I change every comment whose code I changed, in this same edit?     (rail 1)
[ ] Where I reference history, is the past genuinely the reason?            (rail 2)
[ ] Does each guard say which way it fails, and that it is intended?
[ ] Have I named the obvious alternative and why it does not work here?
[ ] Any commented-out code, ownerless TODOs, or bare ticket numbers left?
```

## Backstop

This rule is **self-discipline, with one advisory check**. No hook can read a comment for accuracy, and an `Edit` that changes a comment is indistinguishable at the tool boundary from an `Edit` that changes code.

The review checklist in [`workflows/code-review.md`](../../workflows/code-review.md) carries the line "comments explain why, not what", so Rex will raise a restated-code or stale comment as a finding. That is a judgment call on a diff, it is non-blocking, and it can only see comments the diff touches — a comment that went stale because the code around it moved is invisible to it. The rails above are what keep that from happening; the review pass is what catches it when they do not.

The cost of following this rule is a few sentences per non-obvious decision. The cost of skipping it is a codebase where the reasons are gone, the workarounds look like mistakes, and the comments that remain cannot be trusted.

---

*Part of [ApexYard](https://github.com/me2resh/apexyard) — multi-project SDLC framework for Claude Code · MIT.*

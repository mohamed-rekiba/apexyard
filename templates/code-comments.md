<!-- Source: ApexYard · templates/code-comments.md · github.com/me2resh/apexyard · MIT -->

<!--
  HOW TO USE THIS TEMPLATE

  This one is unlike the others. A README or a PRD has a document shape you
  fill in; comments do not. What a comment needs is a decision — "does this
  one earn its place, and what does it have to say?" — so this file is a
  pattern catalogue rather than a form.

  Use it two ways: as a checklist before committing, and as a starting shape
  when you know a comment is warranted but not how to write it. Copy the
  pattern, not the prose.

  The rule: comment what the code CANNOT say — the why, the constraint, and
  the trap. Never restate the what. The code already says what happens and is
  authoritative in a way a comment can never be, because nothing checks a
  comment. A wrong one passes tests, types, and review, and is then believed.

  Standard: .claude/rules/comment-quality.md
  Voice per surface: .claude/rules/docs-quality.md § "Which voice belongs where"
-->

# Code comment patterns

Four comments earn their place. Everything else is usually noise.

## 1. Why this, and not the obvious thing

The highest-value comment in any codebase. Name the approach the next reader
will reach for, and why it fails here — otherwise the "simplification" gets
made, the tests still pass, and the original problem returns months later.

```bash
# Check emptiness BEFORE expanding. Under `set -u`, bash 3.2 (still the
# system bash on macOS) errors on "${arr[@]}" when arr is empty, so the
# no-match path must exit before the assignment, not after it.
if [ "${#SELECTED[@]}" -eq 0 ]; then
```

```
# {The obvious approach} does not work here because {constraint}.
# {What breaks, concretely, if someone switches back to it.}
```

## 2. The trap

A portability quirk, an ordering constraint, a footgun in a dependency —
something a reader cannot derive from the code and that every reader touching
this line needs.

```bash
# BSD sed silently IGNORES \b where GNU sed honours it, so a word-boundary
# match passes in CI and fails on a maintainer's laptop with no error.
# Use [[:space:]] delimiters instead.
```

```
# {Tool/platform} behaves differently from {expectation}: {the difference}.
# Symptom when it bites: {what the reader would otherwise chase}.
```

## 3. The deliberate omission

The check that is intentionally *not* here, so the next reader does not
helpfully add it. Without the comment, an omission reads as an oversight.

```bash
# Why no `infrastructure/` directory pattern: testing showed it matches
# `docs/infrastructure/notes.md` and `src/types/infrastructure/foo.ts` as
# false positives — the word is ambiguous between IaC and library code.
# Terraform is caught unambiguously via \.tf$ at any depth instead.
```

```
# Deliberately NOT {handling X / matching Y / validating Z}: {why}.
# {What to do instead, or what would have to change for it to be added.}
```

## 4. The fail direction

For any guard, gate, or validator: which way it fails when it cannot decide,
and that this is intended. The control flow never shows intent.

```bash
# No target extractable at all — fail CLOSED. An ambiguous write target
# falls through to the ticket gate rather than past it; a false block is
# recoverable, an unguarded write is not.
```

```
# Fails {open|closed} when {the undecidable case}, because {which error
# is the cheaper one to make}.
```

---

## Before committing

```
[ ] Does each comment say something the code below cannot?
[ ] Did I change every comment whose code I changed, in this same edit?
[ ] Where I reference history, is the past genuinely the reason?
[ ] Does each guard say which way it fails, and that it is intended?
[ ] Have I named the obvious alternative and why it does not work here?
[ ] Any commented-out code, ownerless TODOs, or bare ticket numbers left?
```

## The two rails

1. **A comment describes current behaviour.** Change it in the same edit as
   the code — nothing will remind you, and a stale comment is strictly worse
   than none: it is read as authoritative, contradicts the code silently, and
   survives review because reviewers read diffs and the comment is not in the
   diff.

2. **Reference history only when the past is the reason.** "This used to be a
   for-loop" is noise — that is what `git log` is for. "This is advisory; it
   was blocking until the text-matching approach proved unsound" is
   load-bearing: it stops the next reader re-tightening it and re-earning the
   same failure. State current behaviour first, then the reason.

## What not to write

| Anti-pattern | Why it fails |
|--------------|-------------|
| `i++  // increment i` | A second thing to keep in sync, saying nothing. |
| Commented-out code | Dead or disabled? Nobody can tell, so nobody deletes it. Git holds it. |
| `// TODO: fix this` | No owner, no condition — becomes wallpaper. Write what would have to be true to do it. |
| `# see #412` | Makes the reader leave the file to learn one sentence. Write the sentence; keep the link. |
| Change log in a file header | Duplicates `git log`, drifts immediately, pushes the real contract below the fold. |
| `// hacky but works` | Says something is wrong and nothing about what. Explain why it must be this way, or fix it. |
| `@param userId The user ID` | Restates the signature. Document the constraint instead: what makes it invalid, and what happens then. |
| A workaround with no exit condition | It outlives the bug it works around. Say what must change for it to go. |

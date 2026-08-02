# Documentation Quality — Write It as Though It Were Always True

Documentation is read by someone who does not yet know how the system works, and its job is to leave them able to use it. That is a different job from a commit message, which explains a change to someone reading history, and from a PR description, which tells a reviewer where to spend their attention. All three are prose about the same code, which is exactly why they get confused — and the confusion has a signature: a document that narrates its own edit history instead of describing the system.

This rule is the documentation-wide sibling of [`readme-quality.md`](readme-quality.md), which governs the front door specifically. Everything below applies to guides, rules, runbooks, skill files, reference pages, and explanations — every document except the README, the AgDR, and the four surfaces in the table below that have rules of their own.

## Which voice belongs where

Every surface an agent writes prose to has a different reader and a different tense. This is the canonical table; the other writing rules link here rather than restating it, because a table copied into six files is a table that disagrees with itself within a quarter.

| Surface | Reader | Tense and voice | Rule |
|---------|--------|-----------------|------|
| **Commit message** | someone reading history later, usually while debugging | **Past-facing.** "Previously X, which caused Y; this changes it to Z" belongs here — and only here | [`git-conventions.md`](git-conventions.md) § "Commit message content" |
| **PR description** | a reviewer deciding where to spend judgment | Change-oriented: what changed *and* why it matters to them | [`pr-quality.md`](pr-quality.md) § "Summary bullets" |
| **In-code comment** | the next person to edit this line | **Present.** Why the code is the way it is | [`comment-quality.md`](comment-quality.md) |
| **Documentation, rules, guides** | someone learning the system now | **Present, first-time.** The system as it is, as though it has always been this way | this file |
| **README** | someone deciding whether this project is for them | Present, answering four questions in order | [`readme-quality.md`](readme-quality.md) |
| **In-thread status update** | the operator, right now | A colleague speaking | [`reporting-style.md`](reporting-style.md) |
| **AgDR / ADR** | someone asking why a call was made | **Past, deliberately.** A record of a moment, including options rejected | [`agdr-decisions.md`](agdr-decisions.md) |

The leak that actually happens is **commit voice in a document**. It looks like this:

> Since #3, the gate applies the `qa` label on merge. Before that it closed the ticket directly, which skipped verification.

Every fact there is true, and a reader who wants to know what the gate does now has to reconstruct it by diffing two sentences. Written as documentation:

> On merge, the gate applies the `qa` label rather than closing the ticket, so a merged change is verified before it counts as done.

The rejected alternative is not lost — it belongs in the commit that made the change and in the AgDR that decided it. Both are one link away, and neither is in the reader's path.

## The rule

**Pick one Diataxis mode per document and stay in it. Describe the system as it is. Verify every command against the repo.**

### Pick the mode first

Diataxis splits documentation into four modes. They answer different questions for readers in different states, and a document that mixes them serves none of them well.

| Mode | The reader's question | What it looks like | What kills it |
|------|----------------------|--------------------|---------------|
| **Tutorial** | "Can I get this working at all?" | A guided path with a guaranteed end state | Choices, caveats, and alternatives — the reader has no basis to decide yet |
| **How-to** | "How do I accomplish X?" | Steps for one goal, assuming competence | Teaching fundamentals mid-task |
| **Reference** | "What are the exact parameters?" | Complete, structured, dry, scannable | Narrative and opinion |
| **Explanation** | "Why does it work this way?" | Context, trade-offs, alternatives, history | Step-by-step instructions |

A quickstart that pauses to enumerate three configuration strategies has become an explanation and stopped being a quickstart. Split it: the tutorial picks one path and links to the explanation for readers who want the others.

### Then write it

- **Write as though it is the first time.** The document describes the system, not the sequence of edits that produced it. No "since", "previously", "now", "as of", "this used to". If a past decision is genuinely load-bearing for understanding the current design, state the current design first and give the reason second — see the rails below.
- **Lead each section with the answer, then support it.** A reader scanning for one fact should find it in the first sentence, not after three paragraphs of setup.
- **One source of truth; link, don't duplicate.** Duplicated prose is how documentation drifts: two copies, one updated, and the reader cannot tell which is current. Put the content where it belongs and link to it from everywhere else.
- **Scale to the subject.** A two-flag script does not need an architecture section. Proportionality is part of the standard, not an exception to it.
- **Give every rule a reason.** "Always pass `--repo`" is unfollowable at the edges; "always pass `--repo`, because issue numbers collide across repos and `gh` resolves a bare number against the current directory" tells the reader when it matters and lets them handle the case you did not anticipate.
- **Name the reader's next step.** End a document knowing where the reader goes — the next guide, the reference for the flags, the skill that automates it.
- **Show the thing, then explain it.** A command, a diagram, or an example first; the prose that interprets it second. A diagram with no explanatory sentence shows what the components are and never says why each one exists.

## Two honesty rails (non-negotiable)

These are the rails because they are the two ways a document stops being merely unhelpful and becomes *wrong* — actively worse than no document at all.

1. **Present tense describes only what ships today.** Never write a planned capability, a proposed gate, or an intended guarantee as though it exists. Unbuilt things go under a clearly-marked future-work heading and nowhere else.

   The sharpest form of this in a governance framework is **describing enforcement that does not exist**. A rule that reads as though a hook backs it will be trusted as though a hook backs it, and the reader stops checking. If the mechanism is self-discipline, the document says the word "self-discipline". If a hook is advisory, the document says it warns and does not block. If a component is unavailable to the reader — premium, unreleased, planned — the document says that in the sentence that names it, not in a footnote.

2. **State absences; do not omit them.** No tests, no CI, no rollback path, no monitoring — write it plainly under the relevant heading. Deleting a section to tidy up converts a known gap into an implied capability, and a reader cannot tell "not applicable" from "missing" unless you tell them.

### When history earns its place

Rail 1 forbids narrating a document's edit history. It does not forbid *all* reference to the past, and the distinction is the same one [`comment-quality.md`](comment-quality.md) draws for comments: **reference history only when the past is the reason.**

The test is whether a reader who doesn't know the history would make a mistake without it. Two cases pass:

- **A retracted claim.** When a document previously stated something untrue and readers acted on it, saying so is a correction, not a change log. `right-size-ceremony.md` states plainly that earlier versions cited a token-metering hook that does not ship in this repository — a reader who saw that claim needs to know it was withdrawn, and silently deleting it would leave them still believing it.
- **A semantic change that alters how to read the current behaviour.** When a guard, gate, or warning still exists but now means something different, a reader who remembers the old meaning will misinterpret the new one. Naming the change prevents that misreading.

Both still lead with the present. "This is advisory; it was blocking until the text-matching approach proved unsound" reads correctly. "Since #1026 this is advisory" makes the reader reconstruct the present from the past, which is the failure rail 1 is about.

Everything else — a renamed function, a refactored implementation, a feature that landed in some release — belongs in the commit and the AgDR, not the document.

## Anti-patterns

| Anti-pattern | Why it fails |
|--------------|-------------|
| **Changelog voice** — "since #3…", "previously…", "this now does…" | The reader has to reconstruct the current state by diffing prose. The history belongs in the commit and the AgDR, both one link away. |
| **Enforcement described that doesn't exist** | The worst failure a governance document can have: the reader trusts a gate that is not there and stops checking the thing themselves. |
| **Mixed Diataxis modes** | A tutorial interrupted by a configuration reference loses the reader mid-path and is useless as reference afterwards. |
| **Untested commands** | The highest-cost defect, because every reader hits it and it is invisible to an author whose environment is already configured. |
| **Duplicated prose** | Two copies drift within a quarter and the reader cannot tell which is current. Link instead. |
| **Undated relative time** — "recently", "soon", "currently being migrated" | Meaningless six months later, and there is no signal that it has gone stale. |
| **Rules without reasons** | Unfollowable at the edges. The reader either over-applies it or ignores it. |
| **Stale cross-references** | A link to a renamed file or a closed-and-superseded issue costs the reader a detour and teaches them not to trust the links. |
| **Wall of text** | Documentation is scanned, not read. Undifferentiated prose forces linear reading of a reference. |
| **Explanation that instructs, instructions that explain** | Mode confusion in miniature — the reader gets neither the understanding nor the steps. |

## When NOT to reach for this

- **A document that already meets the bar.** Rewriting good documentation into a preferred section order is churn.
- **AgDRs and ADRs.** A decision record is deliberately a record *of a moment*: past tense, options considered, the call made. "We chose X over Y because Z" is correct there and nowhere else. See [`agdr-decisions.md`](agdr-decisions.md).
- **Commit messages and PR bodies.** Their own rules govern them, and their voice is different on purpose — see the table above.
- **Scratch notes, investigation live-docs, and spike memos.** These are working artifacts whose value is the raw thinking. `templates/tickets/investigation.md` has its own shape.
- **A deliberate stub, declared as one.** "This page is a placeholder; the API is not stable yet" is honest. A stub written to *look* finished is what rail 1 prohibits.
- **The operator asked for something else.** "Just give me rough notes, no ceremony" is a legitimate override. Respect it, and say what you left out.

## Verify before publishing

An agent writing documentation has read the repository, which makes it fluent — and fluency is what makes an invented flag plausible. Check against the code, not against your own draft:

- Every command appears in the project's real tooling and matches its real shape.
- Every configuration key, environment variable, and CLI flag exists and is spelled as the code reads it.
- Every file path, link, and cross-reference resolves.
- Every capability described in the present tense exists today.
- Every claimed enforcement maps to a specific hook, test, or gate — named, and correctly described as blocking or advisory.
- Every issue or AgDR reference points at the thing it claims to.

## Self-check before publishing a document

```
[ ] Which Diataxis mode is this, and does the whole document stay in it?
[ ] Does it describe the system as it is, with no "since"/"previously"/"now"?
[ ] Is every present-tense capability actually shipped?                        (rail 1)
[ ] Does every enforcement claim name a real mechanism, correctly?             (rail 1)
[ ] Are gaps — no tests, no CI, no rollback — stated rather than omitted?      (rail 2)
[ ] Did I verify every command, flag, path, and link against the repo?
[ ] Is anything here duplicated from another document instead of linked?
[ ] Does every rule carry its reason?
[ ] Is the length proportional to the subject?
```

If either rail is unchecked the document is wrong, which is a different and worse problem than thin — fix those first.

## Backstop

This rule is **self-discipline only**. No hook fires on "the agent is about to write documentation": a `Write` to a markdown file is indistinguishable at the tool boundary from any other write, and no shell hook can read voice or verify that a described gate exists.

The one place documentation is checked at all is [`/docs-audit`](../skills/docs-audit/SKILL.md), which reviews existing docs against Diataxis coverage and this standard. That is agent judgment against a checklist, it runs on demand, and it examines documents that already exist. Treat it as a review pass, not a gate — it catches a bad document after the fact and does nothing to prevent one being written.

The cost of following this rule is a slower first draft. The cost of skipping it is documentation that reads like release notes, promises enforcement nobody built, and sends readers to commands that were never run.

---

*Part of [ApexYard](https://github.com/me2resh/apexyard) — multi-project SDLC framework for Claude Code · MIT.*

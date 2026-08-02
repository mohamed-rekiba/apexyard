<!-- Source: ApexYard · templates/documentation.md · github.com/me2resh/apexyard · MIT -->

<!--
  HOW TO USE THIS TEMPLATE

  A document serves ONE of four readers. Pick the mode first — the rest of
  the shape follows from it:

    1. Tutorial     → "Can I get this working at all?"     (learning)
    2. How-to       → "How do I accomplish X?"             (a goal)
    3. Reference    → "What are the exact parameters?"     (a lookup)
    4. Explanation  → "Why does it work this way?"         (understanding)

  DELETE the three skeletons you are not using. A document that mixes modes
  serves none of its readers: a quickstart that pauses to enumerate three
  configuration strategies has stopped being a quickstart, and a reference
  that narrates is no longer scannable. Split instead, and link.

  Scale to the subject. A two-flag script needs no architecture section.
  Proportionality is part of the standard, not an exception to it.

  Three rails while filling this in:
    - Write as though it is the FIRST time. Describe the system as it is —
      no "since #N", "previously", "now does", "as of". Edit history lives
      in the commit and the AgDR, both one link away.
    - Present tense describes only what SHIPS TODAY. And never describe
      enforcement that does not exist: if the mechanism is self-discipline,
      write the words "self-discipline"; if a hook warns rather than blocks,
      say so.
    - State absences. No tests, no CI, no rollback path — write it plainly.
      A deleted section reads as "not applicable", which is a different and
      stronger claim than "missing".

  Verify before publishing: every command, flag, config key, env var, path,
  and link against the actual repo — not against your own draft.

  Standard: .claude/rules/docs-quality.md
  Strip these HTML comments before publishing.
-->

# {Title — name the task or the subject, not the document type}

<!-- One or two sentences: what this covers and who it is for. A reader who
     opened the wrong page should be able to leave from here. -->

{Summary}

<!-- If the reader may have wanted a different mode, say so and link now.
     "Looking for the full flag list? See {reference}." -->

---

<!-- ═══════════════ MODE 1: TUTORIAL ═══════════════
     Learning-oriented. The reader has never done this. Guarantee an end
     state, make every choice for them, and do not explain alternatives —
     they have no basis to choose yet. Link to the explanation instead. -->

## What you'll build

{The concrete end state, in one sentence. Include a screenshot or sample output.}

## Before you start

- {Prerequisite with a version}
- {Account, key, or tool required}

## Steps

### 1. {Action}

```bash
{command}
```

{What just happened, and what the reader should see. Show real output.}

### 2. {Action}

{…}

## What you have now

{Restate the end state and confirm how to verify it.}

## Next

{The one obvious next document. Not a list of six.}

---

<!-- ═══════════════ MODE 2: HOW-TO GUIDE ═══════════════
     Goal-oriented. Assumes competence. One goal per guide. Do not teach
     fundamentals mid-task — link out. -->

## Goal

{The single outcome this guide achieves.}

## Prerequisites

{What must already be true. Link rather than re-explain.}

## Procedure

1. {Step, with the command or edit}
2. {…}

## Verify it worked

{The check that proves success — a command and its expected output.}

## If it goes wrong

| Symptom | Cause | Fix |
|---------|-------|-----|
| {what the reader sees} | {why} | {what to do} |

---

<!-- ═══════════════ MODE 3: REFERENCE ═══════════════
     Information-oriented. Complete, structured, dry, scannable. No
     narrative, no opinion, no worked tutorial. Accuracy is the whole job. -->

## {Thing being described}

{One-line definition.}

### Options

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `{name}` | {type} | `{default}` | {what it does; what makes it invalid} |

### Behaviour

<!-- Edge cases, ordering guarantees, failure modes, and which way it fails
     when it cannot decide. State absences: "no retry", "not thread-safe". -->

- {…}

### Examples

```bash
{minimal example}
```

---

<!-- ═══════════════ MODE 4: EXPLANATION ═══════════════
     Understanding-oriented. Context, trade-offs, alternatives. No
     step-by-step instructions — link to the how-to. This is the one mode
     where a design's history legitimately appears, and only when the past
     is the reason (see docs-quality.md § "When history earns its place"). -->

## The problem

{What forced this design. The constraint, not the solution.}

## How it works

{The model the reader needs in their head. A diagram belongs here — with a
sentence underneath saying why each component exists, which the diagram
itself never says.}

## Why this and not the obvious alternative

<!-- Name the approach a reader would reach for, and why it does not work
     here. Without this, the "simplification" gets made and the original
     problem returns. -->

{Chose X over Y because of constraint Z. The cost is A, accepted because B.}

## What this does not do

<!-- Deliberate non-goals and known gaps. Stating them is the rail; omitting
     them implies a capability. -->

- {…}

## See also

- {The how-to that puts this into practice}
- {The AgDR that recorded the decision}

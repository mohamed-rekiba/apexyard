<!-- Source: ApexYard · templates/commit-message.md · github.com/me2resh/apexyard · MIT -->

<!--
  HOW TO USE THIS TEMPLATE

  A commit message is read almost entirely by one person: someone months
  from now, mid-debugging, who reached this commit through `git blame` or
  `git bisect` and needs to know what its author was thinking.

  The subject says WHAT changed. The body says WHY. The diff already says HOW.

  This is also the ONE surface in the repository where narrating the past is
  correct. "Previously X, which caused Y; this changes it to Z" belongs here
  and nowhere else — not in a rule file, not in a document, not in a code
  comment. Those describe the system as it stands.

  Standard: .claude/rules/git-conventions.md § "Commit Message Content"
  Voice per surface: .claude/rules/docs-quality.md § "Which voice belongs where"
  Strip these HTML comments before committing.
-->

{type}: {imperative subject, ≤72 chars, no trailing period}

<!--
  SUBJECT
    - Imperative mood: "add", "fix", "remove" — never "added" / "adds".
      It completes "applying this commit will…", which is why git's own
      generated messages read that way.
    - State the CHANGE, not the area. "fix: login bug" names a
      neighbourhood; "fix: reject expired tokens on refresh" names the
      change — the difference between a scannable git log and one you have
      to open commit by commit.
    - Types: feat, fix, refactor, test, docs, chore, style, perf
    - Breaking change: `type!: subject` or `type(scope)!: subject`
-->

{The problem. What was wrong or missing — include the symptom someone would
have searched for.}

{Why this fix and not the obvious one. If a simpler approach exists and does
not work, name it, or someone will try it.}

{Consequences a reviewer cannot see in the diff: behaviour that changes
elsewhere, a migration that must run first, a config key that becomes
required, a follow-up deliberately left undone.}

<!--
  BODY
    - Bullets are fine for a multi-part change. Each still earns its line by
      carrying a reason, not by naming a file.
    - Do NOT restate the diff line by line. It duplicates something
      authoritative and drifts the moment the commit is amended.
    - SKIP the body entirely when the subject genuinely says everything: a
      dependency bump, a typo, a rename with no behaviour change.
    - One logical change per commit. If the body is hard to write, that is
      usually the commit asking to be split.
-->

Refs #{ticket}

<!--
  TICKET LINE
    - `Refs #N` keeps the ticket open for the QA gate (the shipped default).
    - `Closes #N` lets the host close it on merge — correct only when the
      QA gate is opted out via `ticket.qa_label: ""`.
    - See .claude/rules/workflow-gates.md § "QA State is Mandatory".
    - The referenced issue must exist; verify-commit-refs.sh checks it.
-->

<!--
  ─────────────────── WORKED EXAMPLE ───────────────────

  fix: resolve PR HEAD from the forge, not the local working tree

  The merge gates compared marker SHAs against `git rev-parse HEAD`, which
  is the local checkout — rarely the PR branch. Every merge therefore
  needed a `gh pr checkout` first, and any mismatch blocked a merge whose
  reviews were valid and on disk.

  They now resolve the PR's HEAD via `gh pr view --json headRefOid`, with a
  fallback to local HEAD and a visible warning when the call fails on
  network or auth. Keeping the fallback silent was rejected: a gate that
  quietly degrades to a weaker check is worse than one that says so.

  Markers written before this change still validate — the SHA format is
  unchanged, only where it is read from.

  Refs #55

  ─────────────────── ANTI-PATTERNS ───────────────────

  fix: bug                          → unfindable by search, unreadable in log
  chore: updates                    → carries no information at all
  fix: address review comments      → describes process; the thread is gone
                                       in six months
  refactor: update parser.ts        → the path is already in the diff
  wip                               → never reaches main
-->

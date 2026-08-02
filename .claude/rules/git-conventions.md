# Git Conventions

## Branch Naming

Format: `{type}/{TICKET-ID}-{description}`

Examples:

- `feature/ABC-123-add-auth`
- `fix/GH-45-login-bug`
- `docs/ENG-99-update-readme`

**Types**: `feature`, `fix`, `refactor`, `chore`, `docs`, `test`, `spike`, `prototype`, `ci`, `build`, `perf`

The `TICKET-ID` should reference an issue in the project's tracker. Default format: `#58` or `GH-58` (GitHub Issues). The validators in `.claude/hooks/` source the regex from `.tracker.id_pattern` in `.claude/project-config.{defaults,}.json` — the default pattern also matches any uppercase tracker prefix (e.g. `ABC-123`) for teams using Linear, Jira, or similar. See `_lib-tracker.sh` and AgDR-0033 for how to swap the active tracker; ApexYard's out-of-the-box default is per-project GitHub Issues, with one repo's issues never crossing into another repo's PRs.

## PR Title Format

Must match: `type(TICKET): description` or `type(TICKET)!: description` (breaking change)

Regex: `^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|spike|prototype)\(<TICKET_ID_PATTERN>\)!?:`

`<TICKET_ID_PATTERN>` is sourced from `.tracker.id_pattern` so adopters get their own tracker's shape validation. Default matches `#123`, `GH-123`, or `[A-Z]{2,10}-[0-9]+` (Jira / Linear / similar).

- One ticket ID per PR title — multi-ticket titles like `fix(ABC-1,2,3):` are rejected
- GitHub Issues use `#XX` format: `fix(#58): description`
- Breaking changes use `!` before the colon: `feat(#58)!: remove deprecated v1 endpoints`

## Commit Message Format

```
type: subject
type!: subject (breaking change)
type(scope)!: subject (breaking change with scope)

- Detailed change 1
- Detailed change 2

Closes #123
```

**Types**: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `perf`

## Commit Message Content

The format above is checked mechanically. What goes *inside* it is not, and it is the part that matters — a commit message is read almost exclusively by someone debugging, months later, who has found this commit with `git blame` or `git bisect` and needs to know what its author was thinking.

Shape to author against: `templates/commit-message.md`, which carries a worked example and the anti-pattern list. Adopters override it at `<private_repo>/custom-templates/commit-message.md` (see [`templates/README.md`](../../templates/README.md)).

**The subject says what changed. The body says why. The diff already says how.**

### Subject line

- **Imperative mood** — `add`, `fix`, `remove`. Not `added`, not `adds`. The subject completes the sentence "applying this commit will…", which is why every generated commit and every merge commit in git already reads that way.
- **State the change, not the area.** `fix: login bug` names a neighbourhood. `fix: reject expired tokens on refresh` names the change, and it is the difference between a `git log` that can be scanned and one that has to be opened commit by commit.
- **Around 50 characters, hard stop at 72.** Longer subjects get truncated in `git log --oneline`, in blame views, and in most review tooling.
- **No trailing period.** It is a title.

### Body

Write a body whenever the change is not self-evident from its subject — which is most of the time. It should carry what the diff cannot:

- **The problem.** What was wrong, or what was missing. Include the symptom a reader would have searched for.
- **Why this fix and not the obvious one.** If there was a simpler approach that does not work, name it. Otherwise someone will try it.
- **Consequences a reviewer cannot see in the diff** — behaviour that changes elsewhere, a migration that has to run first, a config key that becomes required.
- **The ticket reference**, on its own line at the end (`Closes #123` / `Refs #123`). Which of the two depends on whether your project keeps the QA gate — see [`workflow-gates.md`](workflow-gates.md).

Bullets are fine, and often right for a multi-part change. Each one still has to earn its line by carrying a reason, not by naming a file — the same standard [`pr-quality.md`](pr-quality.md) § "Summary bullets" applies to PR descriptions.

Skip the body when the subject genuinely says everything: a dependency bump, a typo fix, a rename with no behaviour change.

### This is where history voice belongs

A commit message is the one surface in the repository where narrating the past is correct:

> Previously the hook compared marker SHAs against the local working tree's HEAD, which forced a checkout dance before every merge and blocked whenever local was on a different branch. It now resolves the PR's HEAD from the forge instead.

That sentence is exactly right in a commit and exactly wrong in a rule file, a document, or a code comment, where the reader wants the system as it stands. The full breakdown of which voice belongs on which surface is in [`docs-quality.md`](docs-quality.md) § "Which voice belongs where".

### Anti-patterns

| Anti-pattern | Why it fails |
|--------------|-------------|
| `fix: bug`, `chore: updates`, `wip` | Carries no information. The commit is unfindable by search and unreadable in `git log`. |
| `fix: address review comments` | Describes the process, not the change. Six months later nobody has the review thread. |
| Subject naming only the file — `refactor: update parser.ts` | The path is already in the diff. Say what changed about it. |
| Body that restates the diff line by line | Duplicates something authoritative and drifts from it the moment the commit is amended. |
| Several unrelated changes in one commit | Makes the message unwritable, `git bisect` useless, and the revert unsafe. |
| Rationale that lives only in the PR thread | PR threads are on a platform; the commit is in the repository. Put the reasoning where the code is. |

### Self-check before committing

```
[ ] Is the subject imperative, under 72 chars, and specific about what changed?
[ ] Does the body explain WHY, rather than restating the diff?
[ ] Did I name the simpler approach that does not work, if there was one?
[ ] Are consequences a reviewer cannot see in the diff written down?
[ ] Is the ticket referenced on its own line?
[ ] Is this one logical change, or should it be several commits?
```

Enforcement is the format hooks plus self-discipline: `verify-commit-refs.sh` checks that referenced issues exist and the commit-format hook checks the shape, but no hook can judge whether a body explains anything.

## File Staging

**NEVER** use `git add -A`, `git add .`, or `git add --all`. Always add specific files:

```bash
git add src/specific-file.ts
```

This is enforced by the `block-git-add-all.sh` hook.

## No Direct Main

Every change must go through a PR. Zero exceptions. No commits directly to `main`/`master`. Enforced by the `block-main-push.sh` hook.

## No Hardcoded Secrets

No API keys, passwords, tokens, or credentials in code. Use environment variables. Patterns to avoid:

- `api_key=`, `password=`, `secret=`, `token=`
- Cloud account IDs and ARNs
- Database connection strings
- Private keys or certificates

Enforced by the `check-secrets.sh` hook.

---

*Part of [ApexYard](https://github.com/me2resh/apexyard) — multi-project SDLC framework for Claude Code · MIT.*

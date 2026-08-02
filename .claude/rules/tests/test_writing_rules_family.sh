#!/bin/bash
# Structural tests for the writing-rule family (mohamed-rekiba/apexyard#10).
#
# The family is docs-quality, comment-quality, readme-quality, pr-quality,
# reporting-style, and the commit-content section of git-conventions. Every
# member is self-discipline: no hook can lint prose voice, and a Write to a
# markdown file is indistinguishable at the tool boundary from any other write.
# So there is no runtime behaviour to exercise.
#
# What IS mechanically checkable is that the artifacts exist, stay wired into
# CLAUDE.md, keep their rails, and — the load-bearing one — that the canonical
# voice-per-surface table lives in exactly ONE file while the others link to it.
# A table copied into six files disagrees with itself within a quarter, which is
# the drift these tests exist to catch.
#
# Deliberately NOT tested: whether the rules are themselves free of changelog
# voice. A grep for "since #" / "previously" false-positives on every file that
# quotes the anti-pattern in order to prohibit it, and both new rules do. That
# check is agent judgment via /docs-audit, as the rules themselves state.
#
# Test style matches the existing tests/*.sh — bash + grep, no framework.

set -u

SRC_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
RULES_DIR="$SRC_ROOT/.claude/rules"
DOCS_RULE="$RULES_DIR/docs-quality.md"
COMMENT_RULE="$RULES_DIR/comment-quality.md"
GIT_RULE="$RULES_DIR/git-conventions.md"
CODE_RULE="$RULES_DIR/code-standards.md"
REPORT_RULE="$RULES_DIR/reporting-style.md"
CLAUDE_MD="$SRC_ROOT/CLAUDE.md"
DOCS_AUDIT="$SRC_ROOT/.claude/skills/docs-audit/SKILL.md"

fail=0
pass() { echo "PASS: $1"; }
die()  { echo "FAIL: $1" >&2; fail=1; }

# --- 1. Both new rule files exist and carry the footer --------------------
for f in "$DOCS_RULE" "$COMMENT_RULE"; do
  name=$(basename "$f")
  if [ -f "$f" ]; then
    pass "$name exists"
  else
    die "$name missing: $f"
    continue
  fi
  if grep -q "Part of \[ApexYard\]" "$f"; then
    pass "$name has the ApexYard footer"
  else
    die "$name is missing the ApexYard footer"
  fi
done

# --- 2. Each new rule keeps its rails -------------------------------------
# These are the parts that must not be trimmed away. If someone shortens the
# file, the rails are what has to survive.
if grep -qi "present tense" "$DOCS_RULE"; then
  pass "docs-quality states the present-tense rail"
else
  die "docs-quality no longer states the present-tense rail"
fi
if grep -qi "absences are stated\|State absences" "$DOCS_RULE"; then
  pass "docs-quality states the stated-absences rail"
else
  die "docs-quality no longer states the stated-absences rail"
fi
# The governance-specific sharpening of rail 1 — the failure a rule file can
# have that a project README cannot.
if grep -qi "enforcement that does not exist\|enforcement that doesn't exist" "$DOCS_RULE"; then
  pass "docs-quality prohibits describing enforcement that does not exist"
else
  die "docs-quality no longer prohibits describing non-existent enforcement"
fi
if grep -qi "describes current behaviour" "$COMMENT_RULE"; then
  pass "comment-quality states the current-behaviour rail"
else
  die "comment-quality no longer states the current-behaviour rail"
fi
if grep -qi "the past \*\?is\*\? the reason\|past .is. the reason" "$COMMENT_RULE"; then
  pass "comment-quality states the history-only-when-it-is-the-reason rail"
else
  die "comment-quality no longer states the history rail"
fi

# --- 3. The canonical voice table lives in exactly one file ---------------
# docs-quality owns it. Any OTHER rule reproducing the table (rather than
# linking) is the duplication-drift failure the rule itself prohibits.
if grep -q "Which voice belongs where" "$DOCS_RULE"; then
  pass "docs-quality carries the canonical voice-per-surface table"
else
  die "docs-quality no longer carries the voice-per-surface table"
fi

owners=0
for f in "$RULES_DIR"/*.md; do
  grep -q "^## Which voice belongs where" "$f" && owners=$((owners + 1))
done
if [ "$owners" -eq 1 ]; then
  pass "exactly one rule file owns the voice table (found $owners)"
else
  die "the voice table must live in exactly ONE file; found $owners copies"
fi

# The consumers must link to it rather than restate it.
for f in "$COMMENT_RULE" "$GIT_RULE" "$REPORT_RULE"; do
  name=$(basename "$f")
  if grep -q "docs-quality.md" "$f"; then
    pass "$name links to the canonical voice table"
  else
    die "$name does not link to docs-quality.md"
  fi
done

# --- 4. Commit-message CONTENT, not just format ---------------------------
if grep -q "^## Commit Message Content" "$GIT_RULE"; then
  pass "git-conventions covers commit message content"
else
  die "git-conventions has no commit-message-content section"
fi
# The distinguishing claim: the commit body is where history voice belongs.
if grep -qi "history voice belongs" "$GIT_RULE"; then
  pass "git-conventions names the commit as the home of history voice"
else
  die "git-conventions no longer names the commit as the home of history voice"
fi

# --- 5. Wire-up ------------------------------------------------------------
for r in docs-quality comment-quality; do
  if grep -q "@.claude/rules/$r.md" "$CLAUDE_MD"; then
    pass "CLAUDE.md imports $r.md"
  else
    die "CLAUDE.md does not import @.claude/rules/$r.md"
  fi
done

if grep -q "comment-quality.md" "$CODE_RULE"; then
  pass "code-standards points at comment-quality"
else
  die "code-standards does not point at comment-quality"
fi

if grep -q "docs-quality.md" "$DOCS_AUDIT"; then
  pass "/docs-audit audits documents against docs-quality"
else
  die "/docs-audit does not reference docs-quality.md"
fi

# --- 6. The rule count in CLAUDE.md matches the directory -----------------
# Counts *.md directly under .claude/rules/ (the tests/ subdir is excluded by
# the glob, which does not recurse).
actual=0
for f in "$RULES_DIR"/*.md; do
  [ -f "$f" ] && actual=$((actual + 1))
done
if grep -q "| $actual modular rule files" "$CLAUDE_MD"; then
  pass "CLAUDE.md rule count matches the directory ($actual)"
else
  claimed=$(grep -o '| [0-9]\+ modular rule files' "$CLAUDE_MD" | grep -o '[0-9]\+' | head -1)
  die "CLAUDE.md claims ${claimed:-?} modular rule files; the directory has $actual"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "test_writing_rules_family: all assertions passed"
  exit 0
fi
echo "test_writing_rules_family: FAILURES above" >&2
exit 1

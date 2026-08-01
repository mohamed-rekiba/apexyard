#!/bin/bash
# Structural tests for the readme-quality rule (mohamed-rekiba/apexyard#1).
#
# The rule itself is self-discipline (no hook can lint prose quality, and a
# Write to README.md is indistinguishable at the tool boundary from any other
# markdown write). So there's no runtime behaviour to exercise. What we CAN
# assert mechanically is that the artifacts exist and stay wired together, so
# the rule can't silently rot:
#
#   1. .claude/rules/readme-quality.md exists and carries the ApexYard footer.
#   2. CLAUDE.md imports it via @.claude/rules/readme-quality.md.
#   3. CLAUDE.md's rules-count line is updated (>= 20).
#   4. templates/project-readme.md exists and covers the four reader questions.
#   5. The template is NOT named readme.md — that would collide with
#      templates/README.md on a case-insensitive filesystem (macOS, Windows).
#   6. The consuming surfaces (/docs-audit, /handover) reference the template.
#
# Test style matches the existing tests/*.sh — bash + grep, no framework.

set -u

SRC_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
RULE="$SRC_ROOT/.claude/rules/readme-quality.md"
TEMPLATE="$SRC_ROOT/templates/project-readme.md"
CLAUDE_MD="$SRC_ROOT/CLAUDE.md"
DOCS_AUDIT="$SRC_ROOT/.claude/skills/docs-audit/SKILL.md"
HANDOVER="$SRC_ROOT/.claude/skills/handover/SKILL.md"

fail=0
pass() { echo "PASS: $1"; }
die()  { echo "FAIL: $1" >&2; fail=1; }

# 1. Rule file exists + footer
if [ -f "$RULE" ]; then
  pass "rule file exists"
else
  die "rule file missing: $RULE"
fi
if grep -q "Part of \[ApexYard\]" "$RULE" 2>/dev/null; then
  pass "rule file has ApexYard footer"
else
  die "rule file missing the ApexYard footer"
fi

# The two honesty rails are the load-bearing half of the rule — if someone
# trims the file down, these are the parts that must not go.
if grep -qi "present tense" "$RULE" 2>/dev/null; then
  pass "rule states the present-tense rail"
else
  die "rule no longer states the present-tense honesty rail"
fi
if grep -qiE "state absences|absences.*(stated|omit)" "$RULE" 2>/dev/null; then
  pass "rule states the stated-absences rail"
else
  die "rule no longer states the stated-absences honesty rail"
fi

# 2. CLAUDE.md imports the rule
if grep -q '@.claude/rules/readme-quality.md' "$CLAUDE_MD" 2>/dev/null; then
  pass "CLAUDE.md imports readme-quality.md"
else
  die "CLAUDE.md does not import @.claude/rules/readme-quality.md"
fi

# 3. CLAUDE.md rules-count line is present and at least 20. Lower bound, not
# an exact match, so a later rule addition doesn't spuriously fail this test —
# same convention as test_reporting_style.sh.
RULES_COUNT=$(grep -oE '[0-9]+ modular rule files' "$CLAUDE_MD" 2>/dev/null | grep -oE '^[0-9]+' | head -n 1)
if [ -n "$RULES_COUNT" ] && [ "$RULES_COUNT" -ge 20 ]; then
  pass "CLAUDE.md rules-count is $RULES_COUNT (>= 20)"
else
  die "CLAUDE.md rules-count missing or below 20 (got: '${RULES_COUNT:-none}')"
fi

# 4. Template exists and covers the four reader questions
if [ -f "$TEMPLATE" ]; then
  pass "template file exists"
else
  die "template file missing: $TEMPLATE"
fi
for section in "The Problem" "Demo" "Evaluation" "Testing" "Monitoring" "Quickstart" \
               "Configuration" "Deployment" "Architecture" "Project Structure" \
               "Decisions and Trade-offs" "CI/CD" "Limitations" "Future Work" "License"; do
  if grep -qF "## $section" "$TEMPLATE" 2>/dev/null; then
    pass "template has section: $section"
  else
    die "template missing section: $section"
  fi
done

# 5. Filename collision guard. On a case-insensitive filesystem (macOS,
# Windows) templates/readme.md and templates/README.md are the SAME FILE —
# creating the former silently destroys the templates index. Never rename
# project-readme.md to readme.md.
#
# Assert the HAZARD, not just the symptom. Checking only "is the index still
# intact?" passes on case-SENSITIVE CI (Linux) even if templates/readme.md
# were reintroduced there — the two files coexist happily on Linux and the
# damage only appears later, on a contributor's Mac. So check git's index for
# the exact lowercase path first: git records exact names on every platform.
if git -C "$SRC_ROOT" ls-files --error-unmatch templates/readme.md >/dev/null 2>&1; then
  die "templates/readme.md is tracked — collides with templates/README.md on macOS/Windows"
else
  pass "no tracked templates/readme.md (case-collision hazard absent)"
fi

# Symptom check as well, for the case where the clobber already happened
# locally and hasn't been committed.
if [ -f "$SRC_ROOT/templates/README.md" ]; then
  if grep -q "^# Templates" "$SRC_ROOT/templates/README.md" 2>/dev/null; then
    pass "templates/README.md is still the templates index (not clobbered)"
  else
    die "templates/README.md is no longer the templates index — case-collision clobber?"
  fi
else
  die "templates/README.md missing entirely — case-collision clobber?"
fi

# 6. Consuming surfaces reference the template / rule
if grep -q 'readme-quality.md' "$DOCS_AUDIT" 2>/dev/null; then
  pass "/docs-audit references the readme-quality rule"
else
  die "/docs-audit no longer references the readme-quality rule"
fi
if grep -q 'templates/project-readme.md' "$HANDOVER" 2>/dev/null; then
  pass "/handover references the project-readme template"
else
  die "/handover no longer references the project-readme template"
fi

# The docs-audit structured export keys off finding ID D1 for README findings.
# Renaming it would break audit-history trend rendering across past runs.
if grep -q '| D1 | README' "$DOCS_AUDIT" 2>/dev/null; then
  pass "/docs-audit still reports README findings as D1"
else
  die "/docs-audit README finding ID is no longer D1 — breaks audit-history trends"
fi

if [ "$fail" -eq 0 ]; then
  echo "ALL PASS: readme-quality rule structural tests"
else
  echo "SOME TESTS FAILED" >&2
fi
exit "$fail"

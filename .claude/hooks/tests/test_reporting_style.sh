#!/bin/bash
# Structural tests for the reporting-style rule (me2resh/apexyard#782).
#
# The rule itself is self-discipline (voice can't be linted from a hook), so
# there's no runtime behaviour to exercise. What we CAN assert mechanically is
# that the artifacts exist and are wired in, so the rule can't silently rot:
#
#   1. .claude/rules/reporting-style.md exists and carries the ApexYard footer.
#   2. CLAUDE.md's trigger index names it, so a reader learns when it applies.
#   3. CLAUDE.md's rules-count line is updated (13) and names "reporting style".
#   4. The opt-in output style exists with valid name + description frontmatter.
#
# Test style matches the existing tests/*.sh — bash + grep, no framework.

set -u

SRC_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
RULE="$SRC_ROOT/.claude/rules/reporting-style.md"
CLAUDE_MD="$SRC_ROOT/CLAUDE.md"
STYLE="$SRC_ROOT/.claude/output-styles/human-report.md"

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

# 2. CLAUDE.md's trigger index names the rule.
# The trigger index is the section between "### Quality Rules" and the next
# "###" heading. Scoped deliberately: an unscoped grep also matches CLAUDE.md's
# TEMPLATES table, so it would pass even after the trigger is deleted.
trigger_index() {
  awk '/^### Quality Rules$/{f=1;next} f&&/^### /{exit} f' "$CLAUDE_MD"
}

# Asserts the trigger index names the rule, not that CLAUDE.md `@`-imports it.
# Claude Code loads every .claude/rules/*.md file regardless — verified by
# disabling an import and confirming in a fresh session that the rule was still
# loaded — so an `@` line proved availability that was never in question. A
# trigger saying WHEN the rule applies is what can actually go missing.
if trigger_index | grep -q 'reporting-style'; then
  pass "CLAUDE.md's trigger index names reporting-style"
else
  die "reporting-style is missing from CLAUDE.md's trigger index — nothing says when it applies"
fi

# 3. CLAUDE.md rules-count line is present and at least 13 (>= the count as
# of this rule's own PR, #783). Checked as a lower bound rather than an exact
# match so a later rule addition (e.g. #784's isolated-builds.md, which bumps
# this to 14) doesn't spuriously fail this test — see AgDR-driven rule growth.
RULES_COUNT=$(grep -oE '[0-9]+ modular rule files' "$CLAUDE_MD" 2>/dev/null | grep -oE '^[0-9]+' | head -n 1)
if [ -n "$RULES_COUNT" ] && [ "$RULES_COUNT" -ge 13 ]; then
  pass "CLAUDE.md rules count present and >= 13 (found: $RULES_COUNT)"
else
  die "CLAUDE.md rules-count line missing or below 13 (found: ${RULES_COUNT:-none})"
fi
if grep -qi 'reporting style' "$CLAUDE_MD" 2>/dev/null; then
  pass "CLAUDE.md rules list names 'reporting style'"
else
  die "CLAUDE.md rules list does not name 'reporting style'"
fi

# 4. Output style exists with frontmatter
if [ -f "$STYLE" ]; then
  pass "output style file exists"
else
  die "output style missing: $STYLE"
fi
if grep -qE '^name:[[:space:]]*.+' "$STYLE" 2>/dev/null \
   && grep -qE '^description:[[:space:]]*.+' "$STYLE" 2>/dev/null; then
  pass "output style has name + description frontmatter"
else
  die "output style missing name/description frontmatter"
fi

if [ "$fail" -eq 0 ]; then
  echo "All reporting-style structural tests passed."
  exit 0
else
  echo "Some reporting-style tests FAILED." >&2
  exit 1
fi

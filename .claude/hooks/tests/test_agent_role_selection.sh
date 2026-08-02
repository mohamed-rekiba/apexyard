#!/bin/bash
# Structural tests for the agent-role-selection rule (me2resh/apexyard#788).
#
# The rule closes a gap role-triggers.md leaves open: role activation is
# defined for in-thread edits/diffs, but nothing maps the Agent-tool spawn
# boundary (subagent_type choice) to a role. Like isolated-builds.md, this
# is a self-discipline rule with no runtime behaviour of its own to
# exercise mechanically (see the rule's own "Backstop" section for why no
# PreToolUse guard shipped alongside it). What we CAN assert mechanically
# is that the artifacts exist and are wired in, so the rule can't silently
# rot:
#
#   1. .claude/rules/agent-role-selection.md exists and carries the
#      ApexYard footer.
#   2. CLAUDE.md's trigger index names it, so a reader learns when it applies.
#   3. CLAUDE.md's rules-count line reads 15 and names "agent role
#      selection".
#
# Test style matches the existing tests/*.sh (e.g. test_isolated_builds.sh)
# — bash + grep, no framework.

set -u

SRC_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
RULE="$SRC_ROOT/.claude/rules/agent-role-selection.md"
CLAUDE_MD="$SRC_ROOT/CLAUDE.md"

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
if trigger_index | grep -q 'agent-role-selection'; then
  pass "CLAUDE.md's trigger index names agent-role-selection"
else
  die "agent-role-selection is missing from CLAUDE.md's trigger index — nothing says when it applies"
fi

# 3. CLAUDE.md rules-count line is present and at least 15 (>= the count as
# of this rule's own PR, #788). Checked as a lower bound, not an exact match,
# so a later rule addition doesn't spuriously fail this test — same pattern
# test_reporting_style.sh established for #783.
RULES_COUNT=$(grep -oE '[0-9]+ modular rule files' "$CLAUDE_MD" 2>/dev/null | grep -oE '^[0-9]+' | head -n 1)
if [ -n "$RULES_COUNT" ] && [ "$RULES_COUNT" -ge 15 ]; then
  pass "CLAUDE.md rules count present and >= 15 (found: $RULES_COUNT)"
else
  die "CLAUDE.md rules-count line missing or below 15 (found: ${RULES_COUNT:-none})"
fi
if grep -qi 'agent role selection' "$CLAUDE_MD" 2>/dev/null; then
  pass "CLAUDE.md rules list names 'agent role selection'"
else
  die "CLAUDE.md rules list does not name 'agent role selection'"
fi

if [ "$fail" -eq 0 ]; then
  echo "All agent-role-selection structural tests passed."
  exit 0
else
  echo "Some agent-role-selection tests FAILED." >&2
  exit 1
fi

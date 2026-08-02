#!/bin/bash
# Structural tests for the isolated-builds rule (me2resh/apexyard#784).
#
# The rule itself is self-discipline (a shell hook can't reliably tell "this
# cd target is a persistent worktree" from "this cd target is a /tmp clone
# that happens to still exist right now"), so there's no runtime behaviour
# to exercise for the rule proper. What we CAN assert mechanically is that
# the artifacts exist and are wired in, so the rule can't silently rot:
#
#   1. .claude/rules/isolated-builds.md exists and carries the ApexYard footer.
#   2. CLAUDE.md's trigger index names it, so a reader learns when it applies.
#   3. CLAUDE.md's rules-count line is updated (14) and names "isolated builds".
#
# Test style matches the existing tests/*.sh (e.g. test_reporting_style.sh)
# — bash + grep, no framework.

set -u

SRC_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
RULE="$SRC_ROOT/.claude/rules/isolated-builds.md"
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

# The trigger index is the section between "### Quality Rules" and the next
# "###" heading. Scoping the assertion to it matters: several of these rules are
# ALSO named in CLAUDE.md's TEMPLATES table, so an unscoped grep passes even
# after the trigger is deleted — which is the only part that can actually go
# missing now that every rule file loads regardless.
trigger_index() {
  awk '/^### Quality Rules$/{f=1;next} f&&/^### /{exit} f' "$CLAUDE_MD"
}

# 2. CLAUDE.md names the rule so a reader knows when it applies.
# Not an `@` import: every .claude/rules/*.md file loads regardless of whether
# CLAUDE.md named it, so the import proved availability that was never in
# doubt. The trigger is the part that can actually go missing.
if trigger_index | grep -q 'isolated-builds'; then
  pass "CLAUDE.md's trigger index names isolated-builds"
else
  die "isolated-builds is missing from CLAUDE.md's trigger index — nothing says when it applies"
fi

# 3. CLAUDE.md rules-count line is present and at least 14 (>= the count as
# of this rule's own PR, #784). Checked as a lower bound rather than an exact
# match so a later rule addition (e.g. #788's agent-role-selection.md, which
# bumps this to 15) doesn't spuriously fail this test — same fix applied
# retroactively here that test_reporting_style.sh already used for #783.
RULES_COUNT=$(grep -oE '[0-9]+ modular rule files' "$CLAUDE_MD" 2>/dev/null | grep -oE '^[0-9]+' | head -n 1)
if [ -n "$RULES_COUNT" ] && [ "$RULES_COUNT" -ge 14 ]; then
  pass "CLAUDE.md rules count present and >= 14 (found: $RULES_COUNT)"
else
  die "CLAUDE.md rules-count line missing or below 14 (found: ${RULES_COUNT:-none})"
fi
if grep -qi 'isolated builds' "$CLAUDE_MD" 2>/dev/null; then
  pass "CLAUDE.md rules list names 'isolated builds'"
else
  die "CLAUDE.md rules list does not name 'isolated builds'"
fi

if [ "$fail" -eq 0 ]; then
  echo "All isolated-builds structural tests passed."
  exit 0
else
  echo "Some isolated-builds tests FAILED." >&2
  exit 1
fi

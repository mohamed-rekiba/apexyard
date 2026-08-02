#!/bin/bash
# Tests for the post-merge steps of /approve-merge (mohamed-rekiba/apexyard#3).
#
# Two halves:
#
#   1. BEHAVIOURAL — tracker_label_add is real shell, so exercise it: dispatch
#      per tracker kind, the never-abort contract, and the add-only boundary.
#   2. STRUCTURAL — steps 8a/10/11 are skill prose an agent follows, not code,
#      so the most that can be pinned is that the load-bearing instructions are
#      present and haven't silently rotted. Same shape as the other skill tests.
#
# The load-bearing safety properties, which must not regress:
#   - tracker_label_add can ONLY add a label (never close/reopen/comment/assign)
#   - it never aborts its caller on missing args or an unknown tracker kind
#   - the local branch delete stays behind an empty-content-diff guard, because
#     `git branch -d` refuses after a squash merge (this skill's default)
#   - step 8a labels rather than closes, preserving the mandatory QA gate

set -u

SRC_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SKILL="$SRC_ROOT/.claude/skills/approve-merge/SKILL.md"
LIB="$SRC_ROOT/.claude/hooks/_lib-tracker.sh"
DEFAULTS="$SRC_ROOT/.claude/project-config.defaults.json"

fail=0
pass() { echo "PASS: $1"; }
die()  { echo "FAIL: $1" >&2; fail=1; }

# ---------------------------------------------------------------- behavioural

# Stub the forge CLIs so nothing touches a real host. Each records its argv.
STUB_DIR="$(mktemp -d)"
trap 'rm -rf "$STUB_DIR"' EXIT
for cli in gh glab; do
  cat > "$STUB_DIR/$cli" <<STUB
#!/bin/bash
echo "\$@" >> "$STUB_DIR/${cli}.argv"
exit \${STUB_EXIT:-0}
STUB
  chmod +x "$STUB_DIR/$cli"
done
PATH="$STUB_DIR:$PATH"

# shellcheck source=/dev/null
. "$LIB" 2>/dev/null

if ! command -v tracker_label_add >/dev/null 2>&1 && ! type tracker_label_add >/dev/null 2>&1; then
  die "tracker_label_add is not defined in _lib-tracker.sh"
else
  pass "tracker_label_add is defined"
fi

# Force a known tracker kind without needing a registry: override tracker_kind.
tracker_kind() { echo "${FAKE_KIND:-gh}"; }

# 1. gh dispatch produces an add-label call, and nothing more dangerous.
: > "$STUB_DIR/gh.argv"
FAKE_KIND=gh tracker_label_add "o/r" "42" "qa"
if grep -q -- "--add-label qa" "$STUB_DIR/gh.argv" 2>/dev/null; then
  pass "gh adapter applies the label"
else
  die "gh adapter did not emit --add-label (got: $(cat "$STUB_DIR/gh.argv" 2>/dev/null))"
fi
if grep -qE "issue (close|reopen|comment)|--add-assignee" "$STUB_DIR/gh.argv" 2>/dev/null; then
  die "gh adapter performed an action beyond adding a label"
else
  pass "gh adapter is add-only (no close/reopen/comment/assign)"
fi

# 2. glab dispatch — including the add-only boundary. Asserting add-only on the
#    gh adapter alone left the glab path unguarded: widening it to `issue close`
#    passed the whole suite.
: > "$STUB_DIR/glab.argv"
FAKE_KIND=glab tracker_label_add "o/r" "42" "qa"
if grep -q -- "--label qa" "$STUB_DIR/glab.argv" 2>/dev/null; then
  pass "glab adapter applies the label"
else
  die "glab adapter did not emit --label (got: $(cat "$STUB_DIR/glab.argv" 2>/dev/null))"
fi
if grep -qE "issue (close|reopen|note|delete)|--assignee" "$STUB_DIR/glab.argv" 2>/dev/null; then
  die "glab adapter performed an action beyond adding a label"
else
  pass "glab adapter is add-only (no close/reopen/note/assign)"
fi

# 3. Unknown kind is a silent no-op that still returns success.
: > "$STUB_DIR/gh.argv"; : > "$STUB_DIR/glab.argv"
if FAKE_KIND=jira tracker_label_add "o/r" "42" "qa"; then
  pass "unknown tracker kind returns 0 (no-op)"
else
  die "unknown tracker kind returned non-zero — would abort the caller"
fi
if [ -s "$STUB_DIR/gh.argv" ] || [ -s "$STUB_DIR/glab.argv" ]; then
  die "unknown tracker kind still invoked a forge CLI"
else
  pass "unknown tracker kind invoked no CLI"
fi

# 4. Missing args never abort the caller.
for args in '"" "42" "qa"' '"o/r" "" "qa"' '"o/r" "42" ""'; do
  if eval "tracker_label_add $args" >/dev/null 2>&1; then
    pass "missing-arg form ($args) returns 0"
  else
    die "missing-arg form ($args) returned non-zero — would abort the caller"
  fi
done

# 5. A host rejection surfaces as non-zero so the caller can warn — but the
#    caller is documented to continue. Verify the signal exists.
: > "$STUB_DIR/gh.argv"
if STUB_EXIT=1 FAKE_KIND=gh tracker_label_add "o/r" "42" "qa" >/dev/null 2>&1; then
  die "host rejection was swallowed — caller cannot warn"
else
  pass "host rejection returns non-zero (caller warns, does not abort)"
fi

# ------------------------------------------------------------------ structural

[ -f "$SKILL" ] || die "approve-merge SKILL.md missing"

# Step 8a labels; it must NOT close. Closing would bypass Gate 6.
if grep -q "### 8a\." "$SKILL"; then
  pass "skill has step 8a (QA transition)"
else
  die "skill lost step 8a — the QA transition is unperformed again"
fi
if grep -q "Do NOT close the ticket here" "$SKILL"; then
  pass "step 8a explicitly forbids closing (Gate 6 preserved)"
else
  die "step 8a no longer forbids closing — QA gate at risk"
fi
if grep -q "tracker_label_add" "$SKILL"; then
  pass "step 8a uses the forge-agnostic helper"
else
  die "step 8a no longer calls tracker_label_add (hardcoded CLI?)"
fi

# The branch delete must stay behind the content-diff guard. `git branch -d`
# alone would refuse after a squash merge; a bare `-D` would be unsafe.
if grep -q 'git diff "\$MERGE_SHA" "\$MERGED_BRANCH" --stat' "$SKILL"; then
  pass "branch delete is guarded by an empty content diff"
else
  die "content-diff guard missing — branch delete is unsafe or will always fail"
fi
if grep -q "Never hoist the \`-D\` out from behind that check" "$SKILL"; then
  pass "the -D guard rationale is recorded"
else
  die "lost the note explaining why -D is safe only behind the diff guard"
fi

for needle in "### 10. Sync the local working tree" "### 11. Clear the merged PR's session state"; do
  if grep -qF "$needle" "$SKILL"; then
    pass "skill has: $needle"
  else
    die "skill missing: $needle"
  fi
done

# Every new step must be non-fatal to the merge.
if grep -q "must never fail the merge" "$SKILL"; then
  pass "step 8a states the never-fail-the-merge contract"
else
  die "step 8a lost the never-fail-the-merge contract"
fi

# Config key present and defaulted.
if [ "$(jq -r '.ticket.qa_label // empty' "$DEFAULTS" 2>/dev/null)" = "qa" ]; then
  pass "ticket.qa_label defaults to 'qa'"
else
  die "ticket.qa_label missing or not defaulted to 'qa' in project-config.defaults.json"
fi

# --- the inertness guard --------------------------------------------------
#
# These must assert against LIVE CODE, not comments. An earlier version grepped
# for "add-label qa", which matched a comment in the file header — so gutting
# the actual `qa|QA)` case branch left the suite fully green while the feature
# was dead. Strip comment lines before matching.
TRIGGER="$SRC_ROOT/.claude/hooks/detect-role-trigger.sh"
TRIGGER_CODE=$(grep -vE '^[[:space:]]*#' "$TRIGGER" 2>/dev/null)

if printf '%s' "$TRIGGER_CODE" | grep -qE '^[[:space:]]*qa\|QA\)'; then
  pass "detect-role-trigger.sh has a live qa|QA) case branch"
else
  die "the qa|QA) case branch is gone — the QA Engineer would never fire"
fi

# The wrapper is invisible to a hook that only matches `gh issue edit` text,
# because the real CLI call lives inside sourced library code. Without a
# dedicated branch here (and the paired settings.json matcher) the whole
# transition is INERT. Same problem tracker_pr_merge solved in #759.
if printf '%s' "$TRIGGER_CODE" | grep -qE '\btracker_label_add\b'; then
  pass "detect-role-trigger.sh recognises the tracker_label_add wrapper"
else
  die "detect-role-trigger.sh does NOT recognise tracker_label_add — the QA transition is inert (see AgDR-0113)"
fi

if grep -q 'Bash(tracker_label_add \*)' "$SRC_ROOT/.claude/settings.json" 2>/dev/null; then
  pass "settings.json carries the Bash(tracker_label_add *) matcher"
else
  die "settings.json lacks the tracker_label_add matcher — the hook is never invoked for the wrapper shape"
fi

# BEHAVIOURAL, not structural. The grep above only proves the string appears.
# It passed while the extraction was silently broken: the original sed used \b,
# which BSD sed (macOS) does not support, so the prefix strip no-opped and awk
# returned the ISSUE NUMBER instead of the label. Structural assertions cannot
# see that. Drive the hook and check the banner.
#
# The banner is once-per-session, so clear the marker before each case or every
# case after the first reports a false negative.
_fires() {
  rm -rf "$SRC_ROOT/.claude/session/role-fired" 2>/dev/null
  printf '%s' "$1" | bash "$TRIGGER" 2>&1 | grep -c "QA Engineer"
}
QUOTED='{"tool_name":"Bash","tool_input":{"command":"tracker_label_add \"o/r\" \"42\" \"qa\""}}'
BARE='{"tool_name":"Bash","tool_input":{"command":"tracker_label_add o/r 42 qa"}}'
OTHER='{"tool_name":"Bash","tool_input":{"command":"tracker_label_add o/r 42 blocked"}}'
CREATE='{"tool_name":"Bash","tool_input":{"command":"gh issue create --label qa"}}'

[ "$(_fires "$QUOTED")" -ge 1 ] \
  && pass "wrapper (quoted args) fires the QA Engineer banner" \
  || die "wrapper (quoted args) did NOT fire — label extraction is broken (BSD sed \\b?)"
[ "$(_fires "$BARE")" -ge 1 ] \
  && pass "wrapper (bare args) fires the QA Engineer banner" \
  || die "wrapper (bare args) did NOT fire — label extraction is broken"
[ "$(_fires "$OTHER")" -eq 0 ] \
  && pass "wrapper with a non-qa label does not fire" \
  || die "wrapper fired on a non-qa label — extraction is picking the wrong field"
[ "$(_fires "$CREATE")" -eq 0 ] \
  && pass "gh issue create does not fire (transition, not initial state)" \
  || die "gh issue create fired — the create-vs-transition distinction is lost"
rm -rf "$SRC_ROOT/.claude/session/role-fired" 2>/dev/null

# --- correctness guards on the skill's shell ------------------------------

# $TICKETS_FILE was referenced three times and assigned zero times, so the
# redirect failed and the ticket list was never built.
if grep -q 'TICKETS_FILE=$(mktemp)' "$SKILL"; then
  pass "TICKETS_FILE is assigned before use"
else
  die "TICKETS_FILE is used without being assigned — the QA labelling never runs"
fi

# `return` outside a function does not abort an executed script; it warns and
# CONTINUES. A guard written that way falls through into the mutation it guards.
if grep -nE '^[[:space:]]*(return|exit) [0-9]' "$SKILL" | grep -qE 'return 0|exit 1'; then
  die "post-merge steps still use a bare return/exit — guards fall through or abort the flow"
else
  pass "post-merge steps use if-blocks, not bare return/exit"
fi

# Every post-merge step must be gated on the merge having actually succeeded.
if [ "$(grep -c 'MERGE_RC:-1' "$SKILL")" -ge 3 ]; then
  pass "steps 8a/10/11 are each gated on MERGE_RC"
else
  die "a post-merge step is not gated on MERGE_RC — a blocked merge would still label/clean up"
fi

# The diff base must be the merge commit (a fixed point), not the default
# branch (which advances as other PRs land, permanently disabling the guard).
if grep -q 'git diff "\$MERGE_SHA" "\$MERGED_BRANCH"' "$SKILL"; then
  pass "branch-delete guard diffs against the merge commit, not a moving branch"
else
  die "branch-delete guard diffs against a moving ref — it stops firing once another PR lands"
fi

# config_get_or substitutes its fallback on ANY empty value, which makes the
# documented `qa_label: ""` opt-out unexpressible.
if grep -q "config_get_or '.ticket.qa_label'" "$SKILL"; then
  die "qa_label read via config_get_or — the documented \"\" opt-out cannot be expressed"
else
  pass "qa_label is read raw, so an explicit \"\" opt-out is honoured"
fi

if [ "$fail" -eq 0 ]; then
  echo "ALL PASS: approve-merge post-merge tests"
else
  echo "SOME TESTS FAILED" >&2
fi
exit "$fail"

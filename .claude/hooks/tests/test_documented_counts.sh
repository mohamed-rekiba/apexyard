#!/bin/bash
# Guard documented framework counts against drift (mohamed-rekiba/apexyard#13).
#
# Docs state how many hooks, skills, rules, agents, and roles the framework
# ships. Those numbers are right when written and wrong shortly after, and
# nothing notices: a stale count reads exactly like a fresh one. When an agent
# believes one, it writes a fourth copy of the same wrong claim, and the error
# is only caught in review — three consecutive review blocks, in the case that
# prompted this test.
#
# The count formulas below come verbatim from
# docs/agdr/AgDR-0046-site-counts-drift-prevention.md, which built this guard
# once for site/*.html. It was retired in #663 only because site/ moved to its
# own repository, taking its assertion targets with it. The mechanism was never
# faulted, so this re-applies it to the docs that stayed.
#
# Style matches the sibling tests: bash + grep, no framework.

set -u

SRC_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$SRC_ROOT" || { echo "FAIL: cannot cd to $SRC_ROOT" >&2; exit 1; }

fail=0
pass() { echo "PASS: $1"; }
die()  { echo "FAIL: $1" >&2; fail=1; }

# ---------------------------------------------------------------------------
# Ground truth
# ---------------------------------------------------------------------------
# AgDR-0046 writes the hook count as `ls .claude/hooks/*.sh | grep -v
# "_lib\|/tests/"`. That exact form trips shellcheck's SC2010 at warning
# severity, which is what CI enforces, so the loop below computes the same
# thing: every `*.sh` directly in the hooks directory that is not a `_lib-*`
# helper. The `/tests/` half of the original filter never did anything — the
# glob does not recurse — so nothing is lost by dropping it.
n_hooks=0
for f in .claude/hooks/*.sh; do
  case "${f##*/}" in _lib*) continue ;; esac
  n_hooks=$((n_hooks + 1))
done

n_skills=$(find .claude/skills -name SKILL.md | wc -l | tr -d ' ')
n_roles=$(find roles -name "*.md" -not -name "README*" -not -path "*/agdr/*" | wc -l | tr -d ' ')
n_rules=$(find .claude/rules -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
n_agents=$(find .claude/agents -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')

for pair in "hooks:$n_hooks" "skills:$n_skills" "roles:$n_roles" "rules:$n_rules" "agents:$n_agents"; do
  if [ -z "${pair#*:}" ] || [ "${pair#*:}" -eq 0 ] 2>/dev/null; then
    die "ground truth for ${pair%%:*} came back 0 — the formula is broken, not the docs"
  fi
done
[ "$fail" -eq 0 ] && pass "ground truth: $n_hooks hooks, $n_skills skills, $n_rules rules, $n_agents agents, $n_roles roles"

# ---------------------------------------------------------------------------
# Which documents get checked
# ---------------------------------------------------------------------------
# Point-in-time records are excluded on purpose. A changelog entry, an AgDR, or
# a spike memo states the count as of its own date; correcting it later would
# falsify the record. `workspace/` holds managed-project clones — their docs
# describe their own projects, not this framework.
files=$(find . -name '*.md' \
  -not -path './.git/*' \
  -not -path './node_modules/*' \
  -not -path './workspace/*' \
  -not -path './docs/agdr/*' \
  -not -path './docs/spikes/*' \
  -not -path './docs/spike-memos/*' \
  -not -path './.claude/session/*' \
  -not -name 'CHANGELOG.md' \
  | sort)

[ -n "$files" ] || die "found no markdown to scan — the find filters are wrong"

# ---------------------------------------------------------------------------
# Known-good lines that match the patterns but are not inventory claims
# ---------------------------------------------------------------------------
# Every entry needs a reason. A new false positive should land here with one,
# not be silenced by loosening the patterns — a looser pattern hides real drift.
skip_line() {
  case "$1" in
    # Per-department subtotals in docs/whats-inside.md: "### Engineering (7 roles)".
    # Correct as written, and they do not sum to the framework total.
    \#*\([0-9]*\ roles\)*) return 0 ;;
    # /status prose about invoking sibling skills, not a count of the library.
    *"instead of running "[0-9]*" skills"*) return 0 ;;
  esac
  return 1
}

# A named subset being enumerated — "12 roles: Heads-of-X, Tech Lead, …" — is a
# claim about a partition, not about the framework total, so the total is the
# wrong thing to compare it against. Whether the partition itself sums correctly
# is a separate question this test cannot answer; see role-triggers.md.
skip_match() {
  case "$1" in
    *"roles:") return 0 ;;
  esac
  return 1
}

# ---------------------------------------------------------------------------
# Scan
# ---------------------------------------------------------------------------
# Nouns are deliberately narrow. Bare "agents" and bare "rules" are excluded
# because prose uses them constantly ("spawns ~10-20 agents", "3 of 5 agents"),
# while every real inventory claim in this repo says "sub-agents" and
# "rule files". Narrow patterns miss less than loose ones cost.
#
# Two shapes are skipped wherever they appear:
#   - a range     — "10-20 agents", "3-5 roles"   (preceded by - – ~)
#   - open-ended  — "40+ hooks"                    (number followed by +)

# LC_ALL=C keeps awk byte-oriented. Without it, an en-dash in the prose ("~10-20
# agents") aborts the record with a multibyte conversion error and the rest of
# the input is silently skipped — a counts guard that quietly stops scanning is
# worse than no guard, because it still reports PASS.
violations=$(printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 grep -nE \
  '[0-9]+\+? (shell scripts|hooks|slash commands|skills|modular rule files|rule files|sub-agents|role definitions|role files|roles)([^a-z]|$)' \
  2>/dev/null | LC_ALL=C awk -F: -v OFS=: \
    -v t_hooks="$n_hooks" -v t_skills="$n_skills" -v t_rules="$n_rules" \
    -v t_agents="$n_agents" -v t_roles="$n_roles" '
function truth_for(noun) {
  if (noun == "shell scripts"      || noun == "hooks")          return t_hooks
  if (noun == "slash commands"     || noun == "skills")         return t_skills
  if (noun == "modular rule files" || noun == "rule files")     return t_rules
  if (noun == "sub-agents")                                     return t_agents
  if (noun == "role definitions"   || noun == "role files" || noun == "roles") return t_roles
  return -1
}
{
  file = $1; lineno = $2
  text = $0
  sub(/^[^:]*:[^:]*:/, "", text)

  rest = text
  offset = 0
  while (match(rest, /[0-9]+\+? (shell scripts|hooks|slash commands|skills|modular rule files|rule files|sub-agents|role definitions|role files|roles)/)) {
    hit   = substr(rest, RSTART, RLENGTH)
    start = offset + RSTART

    # Character immediately before the number: a range or approximation marker
    # means this is not an inventory claim. In C locale the leading byte of a
    # multibyte dash (en/em) compares >= "\200", which is how "10-20 agents"
    # written with a typographic dash is recognised as a range.
    prev = (start > 1) ? substr(text, start - 1, 1) : ""

    open_ended = (hit ~ /\+/)
    ranged     = (prev == "-" || prev == "~" || prev >= "\200")

    if (!open_ended && !ranged) {
      n = hit; sub(/[^0-9].*$/, "", n)
      noun = hit; sub(/^[0-9]+\+? /, "", noun)
      want = truth_for(noun)
      # The character after the noun distinguishes an enumerated subset
      # ("12 roles: Tech Lead, …") from a bare total; skip_match() reads it.
      after = substr(text, start + length(hit), 1)
      if (want >= 0 && n + 0 != want + 0)
        print file ":" lineno "\t" n " " noun (after == ":" ? ":" : "") "\t(actual: " want ")\t" text
    }

    offset = offset + RSTART + RLENGTH - 1
    rest = substr(rest, RSTART + RLENGTH)
  }
}')

# Apply the skip list to whatever survived.
real_violations=""
while IFS= read -r v; do
  [ -n "$v" ] || continue
  line_text=$(printf '%s' "$v" | cut -f4-)
  match_text=$(printf '%s' "$v" | cut -f2)
  skip_line "$line_text" && continue
  skip_match "$match_text" && continue
  real_violations="${real_violations}${v}
"
done <<EOF
$violations
EOF

if [ -n "$(printf '%s' "$real_violations" | tr -d '[:space:]')" ]; then
  die "documented counts have drifted from the tree:"
  printf '%s' "$real_violations" | while IFS= read -r v; do
    [ -n "$v" ] || continue
    printf '        %s\n' "$v" >&2
  done
  echo "" >&2
  echo "        Fix the document, or — if the number is genuinely not an" >&2
  echo "        inventory claim — add it to skip_line() with a reason." >&2
else
  pass "every documented count matches the tree"
fi

# ---------------------------------------------------------------------------
# The scan must actually be looking at something
# ---------------------------------------------------------------------------
# A regex typo or an over-broad exclusion would make this test pass by scanning
# nothing at all, which is the failure mode a counts guard can least afford.
sentinel=$(printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 grep -clE \
  '[0-9]+ (shell scripts|slash commands|rule files|sub-agents|roles)' 2>/dev/null | wc -l | tr -d ' ')
if [ "$sentinel" -ge 3 ]; then
  pass "scan reached $sentinel documents carrying count claims"
else
  die "only $sentinel documents matched any count pattern — the scan is not looking at the tree"
fi

echo ""
if [ "$fail" -eq 0 ]; then
  echo "=== test_documented_counts: all checks passed ==="
else
  echo "=== test_documented_counts: FAILED ===" >&2
fi
exit "$fail"

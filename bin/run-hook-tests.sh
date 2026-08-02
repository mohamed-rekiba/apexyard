#!/usr/bin/env bash
# Discovery test runner for the ApexYard mechanical-enforcement test suites.
#
# Finds every test_*.sh (and *.test.sh) under the framework's tests/ trees,
# runs each in isolation, prints a per-test PASS/FAIL/SKIP line, and exits
# non-zero if ANY non-quarantined test fails. Reusable locally and in CI
# (.github/workflows/tests.yml). See me2resh/apexyard#526.
#
# Usage:
#   bin/run-hook-tests.sh                    # run the whole suite
#   bin/run-hook-tests.sh --list             # list discovered tests, run nothing
#   bin/run-hook-tests.sh <filter> [...]     # run only tests whose path matches
#   bin/run-hook-tests.sh --changed          # run only tests for files changed
#                                            #   vs the default branch
#
# WHY FILTERING EXISTS (me2resh/apexyard#7). The suite is 122 tests and takes
# ~256s. That cost is FIXED: it was paid identically for a one-line config
# change and for a six-file diff, because the runner previously accepted no
# argument but --list. Measured over one long session, repeated full runs were
# ~26% of all mechanical time. A scoped run of a single test is ~1s.
#
# The default is deliberately unchanged — a bare invocation still runs
# everything, so CI (.github/workflows/tests.yml) and the pre-push gate keep
# their full-suite guarantee. Filtering is opt-in, for the edit/verify loop
# where you are iterating on one hook and want the answer in a second rather
# than four minutes. ALWAYS run the full suite once before pushing; a filtered
# run cannot tell you what you broke elsewhere.
#
# Quarantine: tests that genuinely cannot run headless (or are known-failing
# and tracked for a fix) are listed in QUARANTINE below, each with a reason.
# They are SKIPPED and logged — never silently dropped. Keep this list short
# and every entry must cite why.

set -uo pipefail

# Test isolation (#528): many hooks resolve their ops-root via _lib-ops-root.sh,
# which inside a live Claude Code session honours the session pin
# ($APEXYARD_OPS_PIN_DIR/ops-root-$CLAUDE_CODE_SESSION_ID) and points at the REAL
# fork — so a sandbox-based test would escape onto the real repo (wrong results,
# and for writing hooks like apply-agent-routing / link-custom-skills, real-file
# mutation). Disable the pin for the whole suite so every test resolves by
# walk-up to its own sandbox. No-op in headless CI (no pin). Tests that
# specifically exercise the pin (test_resolve_ops_root_pin.sh) set/unset this
# per-case, so the suite-level default doesn't interfere.
export APEXYARD_OPS_DISABLE_PIN=1

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1

# --- Quarantine list (path :: reason). Empty by default; populated only with
# --- evidence (a CI failure that is environmental, not a real regression). ---
QUARANTINE=(
  # Empty — all five originally-quarantined tests (token_efficiency_wave1,
  # harnessability_scoring, md_to_pdf_fallback, agent_routing_sync_and_drift,
  # handover_clone_prompt) have been fixed and un-quarantined (#528). The gate
  # now enforces the entire suite. Add an entry ONLY with evidence (a genuinely
  # headless-incompatible test), citing why.
)

is_quarantined() {
  local t="$1" entry
  [ "${#QUARANTINE[@]}" -gt 0 ] || return 1
  for entry in "${QUARANTINE[@]}"; do
    [ "${entry%% ::*}" = "$t" ] && return 0
  done
  return 1
}

# Per-test wall-clock cap (Linux `timeout`; falls back to no cap if absent).
TIMEOUT_BIN=""
command -v timeout >/dev/null 2>&1 && TIMEOUT_BIN="timeout 120"
command -v gtimeout >/dev/null 2>&1 && TIMEOUT_BIN="gtimeout 120"

# Portable array population (bash 3.2 on macOS has no `mapfile`).
TESTS=()
while IFS= read -r _t; do
  [ -n "$_t" ] && TESTS+=("$_t")
done < <(
  find .claude/hooks/tests .claude/agents/tests .claude/rules/tests .claude/skills \
       -type f \( -name 'test_*.sh' -o -name '*.test.sh' \) 2>/dev/null | sort
)

TOTAL_DISCOVERED=${#TESTS[@]}

if [ "${1:-}" = "--list" ]; then
  [ "$TOTAL_DISCOVERED" -gt 0 ] && printf '%s\n' "${TESTS[@]}"
  echo "($TOTAL_DISCOVERED tests discovered)"
  exit 0
fi

# --- Optional scoping (#7) -------------------------------------------------
#
# `--changed` maps changed files to their tests by BASENAME CONVENTION: a hook
# or lib named foo-bar.sh is covered by test_foo_bar*.sh (dashes to
# underscores). That convention is what the tree already follows; it is a
# heuristic, not a guarantee, which is why the default stays run-everything and
# why the summary below states plainly how many of the discovered tests ran.
#
# Any other arguments are treated as substring filters against the test path.
FILTERS=()
if [ "${1:-}" = "--changed" ]; then
  base=$(git merge-base HEAD origin/HEAD 2>/dev/null \
      || git merge-base HEAD origin/main 2>/dev/null || echo "")
  changed=$(if [ -n "$base" ]; then git diff --name-only "$base"...HEAD; fi; git diff --name-only; git diff --name-only --cached)
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    stem=$(basename "$f" .sh); stem=${stem//-/_}
    FILTERS+=("$stem")
  done <<< "$(printf '%s\n' "$changed" | sort -u)"
  if [ "${#FILTERS[@]}" -eq 0 ]; then
    echo "--changed: no changed files resolved; nothing to run."
    exit 0
  fi
elif [ "$#" -gt 0 ]; then
  FILTERS=("$@")
fi

if [ "${#FILTERS[@]}" -gt 0 ]; then
  SELECTED=()
  for t in "${TESTS[@]}"; do
    for f in "${FILTERS[@]}"; do
      case "$t" in *"$f"*) SELECTED+=("$t"); break ;; esac
    done
  done
  # Check emptiness BEFORE expanding. Under `set -u`, bash 3.2 (still the
  # system bash on macOS) errors on "${arr[@]}" when arr is empty, so the
  # no-match path must exit before the assignment, not after it.
  if [ "${#SELECTED[@]}" -eq 0 ]; then
    echo "No tests matched [${FILTERS[*]}]. Run bare to execute all $TOTAL_DISCOVERED."
    exit 0
  fi
  TESTS=("${SELECTED[@]}")
  echo "Scoped run: ${#TESTS[@]} of $TOTAL_DISCOVERED tests match [${FILTERS[*]}]"
  echo "NOT a substitute for the full suite — run it bare before pushing."
  echo
fi

pass=0 fail=0 skip=0
FAILED=()

for t in "${TESTS[@]}"; do
  if is_quarantined "$t"; then
    reason=""
    for entry in "${QUARANTINE[@]}"; do
      [ "${entry%% ::*}" = "$t" ] && reason="${entry#* :: }"
    done
    printf 'SKIP %s  (quarantined: %s)\n' "$t" "$reason"
    skip=$((skip+1))
    continue
  fi
  # shellcheck disable=SC2086
  if $TIMEOUT_BIN bash "$t" </dev/null >/tmp/_hooktest.out 2>&1; then
    printf 'PASS %s\n' "$t"
    pass=$((pass+1))
  else
    rc=$?
    printf 'FAIL %s  (rc=%s)\n' "$t" "$rc"
    tail -n 15 /tmp/_hooktest.out | sed 's/^/      | /'
    fail=$((fail+1))
    FAILED+=("$t")
  fi
done

echo
echo "============================================================"
if [ "${#TESTS[@]}" -ne "$TOTAL_DISCOVERED" ]; then
  echo "  hook test suite (SCOPED): PASS=$pass  FAIL=$fail  SKIP(quarantined)=$skip  RAN=${#TESTS[@]} of $TOTAL_DISCOVERED"
else
  echo "  hook test suite: PASS=$pass  FAIL=$fail  SKIP(quarantined)=$skip  TOTAL=${#TESTS[@]}"
fi
echo "============================================================"
if [ "$fail" -gt 0 ]; then
  printf 'FAILED:\n'; printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
exit 0

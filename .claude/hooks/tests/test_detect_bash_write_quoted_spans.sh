#!/bin/bash
# Quoted-span normalisation in _lib-detect-bash-write.sh (me2resh/apexyard#7).
#
# The change blanks the contents of INERT quoted spans before scanning for
# redirection, so text that merely resembles shell syntax stops being read as
# a write. This file exists because the first attempt at that shipped four
# HIGH-severity BYPASSES, all found by security review:
#
#   1. path-qualified shell   /bin/sh -c "echo x > f"      escaped the guard
#   2. command substitution   echo "$(date > f)"           is re-parsed by the
#                                                          shell, so a `>` in a
#                                                          double-quoted span
#                                                          can be real
#   3. apostrophe straddle    echo "it's" > "won't.ts"      two apostrophes in
#                                                          DOUBLE-quoted words
#                                                          merged into one bogus
#                                                          single-quoted span and
#                                                          swallowed the operator
#   4. deletion-only inherits all of the above
#
# Finding 3 needs no adversarial intent whatsoever — ordinary English prose
# with two apostrophes around a redirect is enough.
#
# THE DIRECTION THAT MATTERS. A false positive here is noise; a false NEGATIVE
# lets an unticketed write through the gate. Every "must still be a write" case
# below is therefore load-bearing, and the bypass cases are the reason this file
# exists rather than a nicety.

set -uo pipefail

SRC_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
# shellcheck source=/dev/null
. "$SRC_ROOT/.claude/hooks/_lib-detect-bash-write.sh"

pass=0; fail=0
_w() { # _w <expect:write|inert> <label> <cmd>
  local want="$1" label="$2" cmd="$3" got
  if bash_command_appears_to_write "$cmd"; then got="write"; else got="inert"; fi
  if [ "$got" = "$want" ]; then
    printf 'PASS  %s\n' "$label"; pass=$((pass+1))
  else
    printf 'FAIL  %s  (want=%s got=%s)\n      cmd: %s\n' "$label" "$want" "$got" "$cmd"; fail=$((fail+1))
  fi
}

echo "--- BYPASS PROBES (must be detected as writes) ---"
_w write 'path-qualified /bin/sh -c'      '/bin/sh -c "echo x > src/app.ts"'
_w write 'path-qualified /usr/bin/bash -c' '/usr/bin/bash -c "echo x > src/app.ts"'
_w write 'relative ./sh -c'                './sh -c "echo x > src/app.ts"'
_w write 'command substitution in dquotes' 'echo "$(date > src/app.ts)"'
_w write 'backtick substitution in dquotes' 'echo "`date > src/app.ts`"'
_w write 'apostrophe straddle'             'echo "it'"'"'s" > "won'"'"'t.ts"'
_w write 'deletion-only + shell bypass'    'rm a.txt ; /bin/sh -c "echo pwned > src/app.ts"'
_w write 'sudo sh -c'                      'sudo sh -c "echo x > src/app.ts"'
_w write 'xargs sh -c'                     'echo f | xargs sh -c "echo x > src/app.ts"'
_w write 'env sh -c'                       'env sh -c "echo x > src/app.ts"'
_w write 'su -c'                           'su -c "echo x > src/app.ts"'
_w write 'timeout sh -c'                   'timeout 5 sh -c "echo x > src/app.ts"'

echo
echo "--- GENUINE WRITES (no regression) ---"
_w write 'plain redirect'      'echo hi > file.txt'
_w write 'append'              'echo hi >> file.txt'
_w write 'no space'            'echo hi>file.txt'
_w write 'force clobber'       'echo hi >| file.txt'
_w write 'both streams'        'cmd &> out.log'
_w write 'fd redirect'         'cmd 2> err.log'
_w write 'tee'                 'echo hi | tee file.txt'
_w write 'sed -i'              'sed -i.bak s/a/b/ file.txt'
_w write 'second segment'      'ls ; echo hi > file.txt'
_w write 'python -c'           'python -c "open(\"f\",\"w\").write(1)"'
_w write 'node -e'             'node -e "require(\"fs\").writeFileSync(\"f\",1)"'

echo
echo "--- INERT PROSE (the false positives being fixed) ---"
_w inert 'arrow in single quotes'  "echo 'per-hook 12ms -> total 72ms'"
_w inert 'JSON in single quotes'   "echo '{\"tool\":\"Bash\",\"n\":1}'"
_w inert 'arrow in double quotes'  'echo "cost 256s -> 1s"'
_w inert 'gh body with arrow'      'gh issue create --body "map a -> b"'
_w inert 'commit msg with arrow'   'git commit -m "cut 256s -> 1s"'

echo
echo "============================================================"
echo "  quoted-span normalisation: PASS=$pass FAIL=$fail"
echo "============================================================"
[ "$fail" -eq 0 ]

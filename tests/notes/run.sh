#!/usr/bin/env bash
# Runs every tests/notes/*.test.sh; exits non-zero if any fails.
set -uo pipefail
cd "$(dirname "$0")"
fail=0
for t in ./*.test.sh; do
  if bash "$t"; then echo "PASS ${t#./}"; else echo "FAIL ${t#./}"; fail=1; fi
done
exit $fail

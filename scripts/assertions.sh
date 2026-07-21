#!/usr/bin/env bash
# assertions.sh - Assertion suite for the context packs.
# Turns every verifiable claim of a pack into an executable test.
#
# WHY IT EXISTS (lesson from the br-arquitectura reference project):
# freshness.sh only detects THAT something changed (stamp); this detects
# WHICH CLAIM became false. It is the difference between "the pack may be
# stale" and "line 47 is lying".
#
# THE RULE (this is how packs "learn" from their corrections):
#   Every correction to a pack that is mechanically verifiable MUST
#   end up here as an assertion. Otherwise the error will come back.
#
# USAGE
#   scripts/assertions.sh              # runs all suites
#   scripts/assertions.sh <system>     # only scripts/assertions.d/<system>.sh
#   rc=1 if any claim is false.
#
# How to add one (inside scripts/assertions.d/<system>.sh):
#   afirmar "<what the pack claims>" <expected> "<command that measures it>"
# Compatible with bash 3.2 (macOS).
set -uo pipefail
cd "$(dirname "$0")/.."
. scripts/repo-lib.sh

OK=0; FAIL=0
afirmar() {  # <description> <expected> <command>
  _desc="$1"; _esperado="$2"; _cmd="$3"
  _real="$(eval "${_cmd}" 2>/dev/null | tr -d ' \n')"
  if [ "${_real}" = "${_esperado}" ]; then
    printf "  ok    %-64s = %s\n" "${_desc}" "${_real}"; OK=$((OK + 1))
  else
    printf "  FALSE %-64s expected=%s actual=%s\n" "${_desc}" "${_esperado}" "${_real}"
    FAIL=$((FAIL + 1))
  fi
}

SUITES=""
if [ -n "${1:-}" ]; then
  SUITES="scripts/assertions.d/$1.sh"
  if [ ! -f "${SUITES}" ]; then
    echo "ERROR - ${SUITES} does not exist. Available suites:"
    ls scripts/assertions.d/*.sh 2>/dev/null | sed 's/^/  /' || echo "  (none)"
    exit 2
  fi
else
  SUITES=$(ls scripts/assertions.d/*.sh 2>/dev/null || true)
fi

if [ -z "${SUITES}" ]; then
  echo "No suites in scripts/assertions.d/ - nothing to verify."
  echo "(they are seeded by /repo-map and /system-map with each pack's claims)"
  exit 0
fi

for suite in ${SUITES}; do
  echo "== $(basename "${suite}" .sh) =="
  . "${suite}"
done

echo
echo "Assertions: ${OK} ok, ${FAIL} false"
if [ "${FAIL}" -gt 0 ]; then
  echo "ATTENTION - there are FALSE claims: the corresponding pack is lying."
  echo "Fix the pack and update the assertion; never delete the assertion without fixing."
  exit 1
fi

#!/usr/bin/env bash

# Internal SOPS editor used by migrate-sops-values-3-to-4.sh. The caller
# supplies only protected file paths and structural metadata through the
# environment; plaintext values are never passed as command-line arguments.

set -euo pipefail

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

[[ $# -eq 1 ]] || fail "internal editor requires one decrypted Secret file"
[[ -n "${BIGBANG_MIGRATED_SECRET_FILE:-}" ]] || fail "missing migrated Secret file"
[[ -f "$BIGBANG_MIGRATED_SECRET_FILE" ]] || fail "migrated Secret file is not readable"
[[ -n "${BIGBANG_SECRET_VALUES_KEY:-}" ]] || fail "missing Secret values key"

command -v yq >/dev/null 2>&1 || fail "Mike Farah yq v4 is required"
[[ "$(yq --version 2>/dev/null)" =~ version\ v4\. ]] \
  || fail "Mike Farah yq v4 is required"

HAS_STRING_DATA=$(BIGBANG_VALUES_KEY="$BIGBANG_SECRET_VALUES_KEY" yq -r \
  '(.stringData // {}) | has(strenv(BIGBANG_VALUES_KEY))' \
  "$BIGBANG_MIGRATED_SECRET_FILE")
HAS_DATA=$(BIGBANG_VALUES_KEY="$BIGBANG_SECRET_VALUES_KEY" yq -r \
  '(.data // {}) | has(strenv(BIGBANG_VALUES_KEY))' \
  "$BIGBANG_MIGRATED_SECRET_FILE")

if [[ "$HAS_STRING_DATA" == true && "$HAS_DATA" == true ]]; then
  fail "migrated Secret key is ambiguous: $BIGBANG_SECRET_VALUES_KEY"
elif [[ "$HAS_STRING_DATA" == true ]]; then
  BIGBANG_VALUES_FIELD=stringData
elif [[ "$HAS_DATA" == true ]]; then
  BIGBANG_VALUES_FIELD=data
else
  fail "migrated Secret key is missing: $BIGBANG_SECRET_VALUES_KEY"
fi

BIGBANG_VALUES_FIELD=$BIGBANG_VALUES_FIELD \
BIGBANG_VALUES_KEY=$BIGBANG_SECRET_VALUES_KEY \
BIGBANG_MIGRATED_SECRET=$BIGBANG_MIGRATED_SECRET_FILE \
  yq -i '
    .[strenv(BIGBANG_VALUES_FIELD)][strenv(BIGBANG_VALUES_KEY)] =
      load(strenv(BIGBANG_MIGRATED_SECRET))[strenv(BIGBANG_VALUES_FIELD)][strenv(BIGBANG_VALUES_KEY)]
  ' "$1"

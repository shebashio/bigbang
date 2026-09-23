#!/usr/bin/env bash

# Migrate a Big Bang values payload stored in a SOPS-encrypted Kubernetes
# Secret. The package-path transformation remains owned by
# migrate-values-3-to-4.sh.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MIGRATION_SCRIPT="${SCRIPT_DIR}/migrate-values-3-to-4.sh"
EDITOR_SCRIPT="${SCRIPT_DIR}/migrate-sops-values-3-to-4-editor.sh"
SOPS_BIN=${SOPS_BIN:-sops}

usage() {
  cat <<'EOF'
Usage: migrate-sops-values-3-to-4.sh [OPTIONS] INPUT

Decrypt a SOPS-encrypted Kubernetes Secret, migrate the Big Bang values YAML
stored at stringData["values.yaml"] or data["values.yaml"], and re-encrypt a
copy using the input file's existing SOPS metadata and master keys.

Options:
  -o, --output FILE       Write the encrypted migrated Secret to FILE.
  -i, --in-place         Replace INPUT after creating INPUT.bak.
  -k, --values-key KEY   Secret data key containing values (default: values.yaml).
  -h, --help             Show this help.

Without --output or --in-place, encrypted output is written to standard output.
SOPS authentication and provider selection are inherited from the environment,
for example AWS_PROFILE=dev_sso. Plaintext is held only in a mode-0700 temporary
directory and is removed on exit.
YAML anchors and aliases are expanded automatically and their anchor names are
reported. Expansion must preserve the resolved values structure.

Examples:
  AWS_PROFILE=dev_sso scripts/migrate-sops-values-3-to-4.sh \
    --output secret-4.x.enc.yaml secret.enc.yaml
  AWS_PROFILE=dev_sso scripts/migrate-sops-values-3-to-4.sh \
    --in-place secret.enc.yaml
EOF
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

OUTPUT_FILE=""
IN_PLACE=false
VALUES_KEY="values.yaml"
INPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output)
      [[ $# -ge 2 ]] || fail "$1 requires a file path"
      OUTPUT_FILE=$2
      shift 2
      ;;
    -i|--in-place)
      IN_PLACE=true
      shift
      ;;
    -k|--values-key)
      [[ $# -ge 2 ]] || fail "$1 requires a Secret key"
      VALUES_KEY=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      fail "unknown option: $1"
      ;;
    *)
      [[ -z "$INPUT_FILE" ]] || fail "exactly one input Secret is supported"
      INPUT_FILE=$1
      shift
      ;;
  esac
done

[[ -n "$INPUT_FILE" ]] || fail "one input Secret is required"
[[ -n "$VALUES_KEY" ]] || fail "--values-key cannot be empty"
[[ "$IN_PLACE" != true || -z "$OUTPUT_FILE" ]] \
  || fail "--in-place and --output cannot be used together"
[[ -f "$INPUT_FILE" ]] || fail "input file does not exist: $INPUT_FILE"
[[ -r "$INPUT_FILE" ]] || fail "input file is not readable: $INPUT_FILE"
[[ -x "$MIGRATION_SCRIPT" ]] || fail "migration script is not executable: $MIGRATION_SCRIPT"
[[ -x "$EDITOR_SCRIPT" ]] || fail "SOPS editor is not executable: $EDITOR_SCRIPT"
command -v yq >/dev/null 2>&1 || fail "Mike Farah yq v4 is required"
[[ "$(yq --version 2>/dev/null)" =~ version\ v4\. ]] \
  || fail "Mike Farah yq v4 is required"
command -v "$SOPS_BIN" >/dev/null 2>&1 || fail "sops is required"

if [[ -n "$OUTPUT_FILE" ]]; then
  [[ ! -d "$OUTPUT_FILE" ]] || fail "output path must be a file, not a directory: $OUTPUT_FILE"
  if [[ "$OUTPUT_FILE" == "$INPUT_FILE" ]] \
    || [[ -e "$OUTPUT_FILE" && "$OUTPUT_FILE" -ef "$INPUT_FILE" ]]; then
    fail "output refers to the input file; use --in-place to replace it safely"
  fi
fi

if [[ "$IN_PLACE" == true ]]; then
  BACKUP_FILE="${INPUT_FILE}.bak"
  [[ ! -e "$BACKUP_FILE" ]] || fail "backup already exists: $BACKUP_FILE"
fi

yq -e 'tag == "!!map"' "$INPUT_FILE" >/dev/null 2>&1 \
  || fail "the encrypted Secret must be a YAML mapping: $INPUT_FILE"
yq -e 'has("sops") and ((.sops | tag) == "!!map")' "$INPUT_FILE" >/dev/null 2>&1 \
  || fail "input is not a SOPS-encrypted YAML document: $INPUT_FILE"

umask 077
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bigbang-sops-values-migration.XXXXXX")
chmod 700 "$WORK_DIR"
DECRYPTED_SECRET="${WORK_DIR}/secret.yaml"
MIGRATED_SECRET="${WORK_DIR}/secret-migrated.yaml"
ENCRYPTED_WORK="${WORK_DIR}/secret.enc.yaml"
VERIFIED_SECRET="${WORK_DIR}/verified-secret.yaml"
MIGRATED_JSON="${WORK_DIR}/secret-migrated.json"
VERIFIED_JSON="${WORK_DIR}/verified-secret.json"
REPLACEMENT_FILE=""

cleanup() {
  rm -f "$DECRYPTED_SECRET" "$MIGRATED_SECRET" "$ENCRYPTED_WORK" \
    "$VERIFIED_SECRET" "$MIGRATED_JSON" "$VERIFIED_JSON"
  [[ -z "$REPLACEMENT_FILE" ]] || rm -f "$REPLACEMENT_FILE"
  rmdir "$WORK_DIR" 2>/dev/null || true
}
trap cleanup EXIT

"$SOPS_BIN" --decrypt --output "$DECRYPTED_SECRET" "$INPUT_FILE" \
  || fail "failed to decrypt SOPS input: $INPUT_FILE"

"$MIGRATION_SCRIPT" --secret-key "$VALUES_KEY" \
  --output "$MIGRATED_SECRET" "$DECRYPTED_SECRET"

cp -p "$INPUT_FILE" "$ENCRYPTED_WORK"
BIGBANG_MIGRATED_SECRET_FILE="$MIGRATED_SECRET" \
BIGBANG_SECRET_VALUES_KEY="$VALUES_KEY" \
SOPS_EDITOR="$EDITOR_SCRIPT" \
EDITOR="$EDITOR_SCRIPT" \
VISUAL="$EDITOR_SCRIPT" \
  "$SOPS_BIN" "$ENCRYPTED_WORK" >/dev/null \
  || fail "failed to re-encrypt migrated Secret"

"$SOPS_BIN" --decrypt --output "$VERIFIED_SECRET" "$ENCRYPTED_WORK" \
  || fail "failed to verify the re-encrypted Secret"
yq -o=json -I=0 '.' "$MIGRATED_SECRET" >"$MIGRATED_JSON"
yq -o=json -I=0 '.' "$VERIFIED_SECRET" >"$VERIFIED_JSON"
cmp -s "$MIGRATED_JSON" "$VERIFIED_JSON" \
  || fail "re-encrypted Secret does not match the migrated Secret"

if [[ "$IN_PLACE" == true ]]; then
  cp -p "$INPUT_FILE" "$BACKUP_FILE"
  REPLACEMENT_FILE=$(mktemp "${INPUT_FILE}.tmp.XXXXXX")
  cp -p "$ENCRYPTED_WORK" "$REPLACEMENT_FILE"
  mv "$REPLACEMENT_FILE" "$INPUT_FILE"
  REPLACEMENT_FILE=""
  printf 'Migrated %s; encrypted backup written to %s\n' \
    "$INPUT_FILE" "$BACKUP_FILE" >&2
elif [[ -n "$OUTPUT_FILE" ]]; then
  cp "$ENCRYPTED_WORK" "$OUTPUT_FILE"
  printf 'Encrypted migrated Secret written to %s\n' "$OUTPUT_FILE" >&2
else
  cat "$ENCRYPTED_WORK"
fi

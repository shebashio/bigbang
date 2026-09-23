#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT=$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)
  SCRIPT_PATH="${REPO_ROOT}/scripts/migrate-sops-values-3-to-4.sh"
  INPUT_FILE="${BATS_TEST_TMPDIR}/secret.enc.yaml"
  OUTPUT_FILE="${BATS_TEST_TMPDIR}/secret-4.x.enc.yaml"
  FAKE_SOPS="${BATS_TEST_TMPDIR}/sops"

  cat >"$FAKE_SOPS" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--decrypt" ]]; then
  shift
  output=""
  if [[ "${1:-}" == "--output" ]]; then
    output=$2
    shift 2
  fi
  input=$1
  if [[ -n "$output" ]]; then
    yq 'del(.sops)' "$input" >"$output"
  else
    yq 'del(.sops)' "$input"
  fi
  exit 0
fi

input=$1
if [[ "${FAKE_SOPS_FAIL_EDIT:-false}" == true ]]; then
  exit 1
fi
plaintext="${input}.plaintext"
yq 'del(.sops)' "$input" >"$plaintext"
"$EDITOR" "$plaintext"
yq '.sops = {"mac": "fake", "version": "3.9.0"}' "$plaintext" >"$input"
rm -f "$plaintext"
EOF
  chmod +x "$FAKE_SOPS"
}

run_migration() {
  run --separate-stderr env SOPS_BIN="$FAKE_SOPS" "$SCRIPT_PATH" "$@"
}

@test "documents encrypted Secret migration behavior" {
  run "$SCRIPT_PATH" --help

  [ "$status" -eq 0 ] || {
    printf '%s\n' "$stderr" >&3
    false
  }
  [[ "$output" == *'stringData["values.yaml"] or data["values.yaml"]'* ]]
  [[ "$output" == *"existing SOPS metadata and master keys"* ]]
  [[ "$output" == *"YAML anchors and aliases are expanded automatically"* ]]
  [[ "$output" != *"--expand-anchors"* ]]
}

@test "migrates values stored in Secret stringData" {
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: environment
stringData:
  values.yaml: |
    monitoring:
      enabled: true
    addons:
      gitlab:
        enabled: false
sops:
  mac: fake
  version: 3.9.0
EOF
  cp "$INPUT_FILE" "${INPUT_FILE}.original"

  run_migration --output "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ] || {
    printf '%s\n' "$stderr" >&3
    false
  }
  cmp "$INPUT_FILE" "${INPUT_FILE}.original"
  [ "$(yq '.sops.mac' "$OUTPUT_FILE")" = "fake" ]
  [ "$(yq -r '.stringData."values.yaml"' "$OUTPUT_FILE" | yq '.packageConfiguration.version' -)" = "v1" ]
  [ "$(yq -r '.stringData."values.yaml"' "$OUTPUT_FILE" | yq '.packages.monitoring.enabled' -)" = "true" ]
  [ "$(yq -r '.stringData."values.yaml"' "$OUTPUT_FILE" | yq '.packages.gitlab.enabled' -)" = "false" ]
}

@test "migrates base64-encoded values stored in Secret data" {
  printf '%s\n' 'kiali:' '  enabled: true' >"${BATS_TEST_TMPDIR}/plain-values.yaml"
  base64 <"${BATS_TEST_TMPDIR}/plain-values.yaml" | tr -d '\n' >"${BATS_TEST_TMPDIR}/encoded-values"
  ENCODED_VALUES_FILE="${BATS_TEST_TMPDIR}/encoded-values" yq -n '
    .apiVersion = "v1" |
    .kind = "Secret" |
    .metadata.name = "environment" |
    .data."values.yaml" = load_str(strenv(ENCODED_VALUES_FILE)) |
    .sops.mac = "fake" |
    .sops.version = "3.9.0"
  ' >"$INPUT_FILE"

  run_migration --output "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ] || {
    printf '%s\n' "$stderr" >&3
    false
  }
  yq -r '.data."values.yaml"' "$OUTPUT_FILE" \
    | base64 --decode >"${BATS_TEST_TMPDIR}/migrated-values.yaml"
  [ "$(yq '.packageConfiguration.version' "${BATS_TEST_TMPDIR}/migrated-values.yaml")" = "v1" ]
  [ "$(yq '.packages.kiali.enabled' "${BATS_TEST_TMPDIR}/migrated-values.yaml")" = "true" ]
}

@test "supports a custom Secret values key" {
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: environment
stringData:
  bigbang.yaml: |
    addons:
      argocd:
        enabled: true
sops:
  mac: fake
EOF

  run_migration --values-key bigbang.yaml --output "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ] || {
    printf '%s\n' "$stderr" >&3
    false
  }
  [ "$(yq -r '.stringData."bigbang.yaml"' "$OUTPUT_FILE" | yq '.packages.argocd.enabled' -)" = "true" ]
}

@test "automatically expands and reports anchors in encrypted values" {
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: environment
stringData:
  values.yaml: |
    shared: &shared
      enabled: true
    monitoring: *shared
sops:
  mac: fake
EOF

  run_migration --output "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [[ "$stderr" == *"Warning: expanded YAML anchors and aliases"* ]]
  [[ "$stderr" == *"Expanded anchors:"* ]]
  [[ "$stderr" == *"shared"* ]]
  printf '%s' "$(yq -r '.stringData."values.yaml"' "$OUTPUT_FILE")" \
    >"${BATS_TEST_TMPDIR}/expanded-values.yaml"
  [ "$(yq '.packages.monitoring.enabled' "${BATS_TEST_TMPDIR}/expanded-values.yaml")" = "true" ]
  [ "$(yq '[.. | anchor] | map(select(. != "")) | length' "${BATS_TEST_TMPDIR}/expanded-values.yaml")" = "0" ]
  [ "$(yq '[.. | select(kind == "alias")] | length' "${BATS_TEST_TMPDIR}/expanded-values.yaml")" = "0" ]
}

@test "in-place mode creates an encrypted backup" {
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: environment
stringData:
  values.yaml: |
    grafana:
      enabled: true
sops:
  mac: original
EOF

  run_migration --in-place "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [ -f "${INPUT_FILE}.bak" ]
  [ "$(yq '.sops.mac' "${INPUT_FILE}.bak")" = "original" ]
  [ "$(yq -r '.stringData."values.yaml"' "$INPUT_FILE" | yq '.packages.grafana.enabled' -)" = "true" ]
}

@test "rejects a missing or ambiguous values key" {
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: environment
stringData:
  other.yaml: |
    monitoring:
      enabled: true
sops:
  mac: fake
EOF

  run_migration --output "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"does not contain values.yaml in data or stringData"* ]]

  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: environment
data:
  values.yaml: bW9uaXRvcmluZzoKICBlbmFibGVkOiB0cnVlCg==
stringData:
  values.yaml: |
    monitoring:
      enabled: true
sops:
  mac: fake
EOF

  run_migration --output "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"exists in both data and stringData"* ]]
}

@test "rejects malformed base64 data" {
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: environment
data:
  values.yaml: "not-base64!"
sops:
  mac: fake
EOF

  run_migration --output "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"data.values.yaml is not valid base64"* ]] || {
    printf '%s\n' "$stderr" >&3
    false
  }
  [ ! -e "$OUTPUT_FILE" ]
}

@test "does not replace the input when SOPS re-encryption fails" {
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: environment
stringData:
  values.yaml: |
    monitoring:
      enabled: true
sops:
  mac: original
EOF
  cp "$INPUT_FILE" "${INPUT_FILE}.original"

  run --separate-stderr env \
    SOPS_BIN="$FAKE_SOPS" \
    FAKE_SOPS_FAIL_EDIT=true \
    "$SCRIPT_PATH" --in-place "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"failed to re-encrypt migrated Secret"* ]]
  cmp "$INPUT_FILE" "${INPUT_FILE}.original"
  [ ! -e "${INPUT_FILE}.bak" ]
}

@test "rejects plaintext input and unsafe output targets" {
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: Secret
stringData:
  values.yaml: |
    monitoring:
      enabled: true
EOF

  run_migration --output "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"not a SOPS-encrypted YAML document"* ]]

  yq -i '.sops.mac = "fake"' "$INPUT_FILE"
  run_migration --output "$INPUT_FILE" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$stderr" == *"output refers to the input file"* ]]
}

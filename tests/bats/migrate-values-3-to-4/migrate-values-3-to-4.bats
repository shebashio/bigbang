#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT=$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)
  SCRIPT_PATH="${REPO_ROOT}/scripts/migrate-values-3-to-4.sh"
  INPUT_FILE="${BATS_TEST_TMPDIR}/values.yaml"
  OUTPUT_FILE="${BATS_TEST_TMPDIR}/values-4.x.yaml"
}

@test "moves root and addon packages into the unified package map" {
  cat >"$INPUT_FILE" <<'EOF'
domain: dev.bigbang.mil
monitoring:
  enabled: true
addons:
  gitlab:
    enabled: false
  unexpectedAddon:
    enabled: true
packages:
  podinfo:
    enabled: true
EOF

  run "$SCRIPT_PATH" -o "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [ "$(yq '.packages.monitoring.enabled' "$OUTPUT_FILE")" = "true" ]
  [ "$(yq '.packages.gitlab.enabled' "$OUTPUT_FILE")" = "false" ]
  [ "$(yq '.packages.podinfo.enabled' "$OUTPUT_FILE")" = "true" ]
  [ "$(yq '.addons.unexpectedAddon.enabled' "$OUTPUT_FILE")" = "true" ]
  [ "$(yq 'has("monitoring")' "$OUTPUT_FILE")" = "false" ]
  [ "$(yq '.addons | has("gitlab")' "$OUTPUT_FILE")" = "false" ]
}

@test "deep merges legacy values while the unified path takes precedence" {
  cat >"$INPUT_FILE" <<'EOF'
monitoring:
  enabled: true
  flux:
    timeout: 10m
    interval: 5m
  values:
    serviceMonitor:
      enabled: true
packages:
  monitoring:
    enabled: false
    flux:
      timeout: 20m
EOF

  run "$SCRIPT_PATH" -o "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [ "$(yq '.packages.monitoring.enabled' "$OUTPUT_FILE")" = "false" ]
  [ "$(yq '.packages.monitoring.flux.timeout' "$OUTPUT_FILE")" = "20m" ]
  [ "$(yq '.packages.monitoring.flux.interval' "$OUTPUT_FILE")" = "5m" ]
  [ "$(yq '.packages.monitoring.values.serviceMonitor.enabled' "$OUTPUT_FILE")" = "true" ]
}

@test "stdout mode leaves the input unchanged and migration is idempotent" {
  cat >"$INPUT_FILE" <<'EOF'
addons:
  argocd:
    enabled: true
EOF
  cp "$INPUT_FILE" "${INPUT_FILE}.original"

  run --separate-stderr "$SCRIPT_PATH" "$INPUT_FILE"

  [ "$status" -eq 0 ]
  cmp "$INPUT_FILE" "${INPUT_FILE}.original"
  printf '%s\n' "$output" >"$OUTPUT_FILE"

  run --separate-stderr "$SCRIPT_PATH" "$OUTPUT_FILE"

  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | yq '.packages.argocd.enabled')" = "true" ]
  [[ "$stderr" == *"No legacy built-in package paths found."* ]]
}

@test "in-place mode creates a backup" {
  cat >"$INPUT_FILE" <<'EOF'
kiali:
  enabled: false
EOF

  run "$SCRIPT_PATH" --in-place "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [ -f "${INPUT_FILE}.bak" ]
  [ "$(yq '.kiali.enabled' "${INPUT_FILE}.bak")" = "false" ]
  [ "$(yq '.packages.kiali.enabled' "$INPUT_FILE")" = "false" ]
}

@test "rejects a non-mapping packages value" {
  cat >"$INPUT_FILE" <<'EOF'
packages:
  - invalid
EOF

  run "$SCRIPT_PATH" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"packages must be a YAML mapping"* ]]
}

@test "migrated maintained values remain idempotent and render with the chart" {
  SECOND_OUTPUT_FILE="${BATS_TEST_TMPDIR}/values-4.x-second.yaml"

  run --separate-stderr \
    "$SCRIPT_PATH" -o "$OUTPUT_FILE" "${REPO_ROOT}/tests/test-values.yaml"

  [ "$status" -eq 0 ]

  run helm lint "${REPO_ROOT}/chart" -f "$OUTPUT_FILE"

  [ "$status" -eq 0 ]

  run --separate-stderr \
    "$SCRIPT_PATH" -o "$SECOND_OUTPUT_FILE" "$OUTPUT_FILE"

  [ "$status" -eq 0 ]
  [[ "$stderr" == *"No legacy built-in package paths found."* ]]
  cmp "$OUTPUT_FILE" "$SECOND_OUTPUT_FILE"
}

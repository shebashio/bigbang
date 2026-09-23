#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT=$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)
  SCRIPT_PATH="${REPO_ROOT}/scripts/migrate-values-3-to-4.sh"
  INPUT_FILE="${BATS_TEST_TMPDIR}/values.yaml"
  OUTPUT_FILE="${BATS_TEST_TMPDIR}/values-4.x.yaml"
}

@test "documents v1 as the retained Big Bang 4.x package contract" {
  run "$SCRIPT_PATH" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Big Bang 4.x retains v1 as the default unified package contract"* ]]
  [[ "$output" == *"YAML anchors and aliases are expanded automatically"* ]]
  [[ "$output" != *"--expand-anchors"* ]]
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
  [ "$(yq '.packageConfiguration.version' "$OUTPUT_FILE")" = "v1" ]
  [ "$(yq '.packages.monitoring.enabled' "$OUTPUT_FILE")" = "true" ]
  [ "$(yq '.packages.gitlab.enabled' "$OUTPUT_FILE")" = "false" ]
  [ "$(yq '.packages.podinfo.enabled' "$OUTPUT_FILE")" = "true" ]
  [ "$(yq '.addons.unexpectedAddon.enabled' "$OUTPUT_FILE")" = "true" ]
  [ "$(yq 'has("monitoring")' "$OUTPUT_FILE")" = "false" ]
  [ "$(yq '.addons | has("gitlab")' "$OUTPUT_FILE")" = "false" ]
}

@test "deep merges legacy values while the unified path takes precedence" {
  cat >"$INPUT_FILE" <<'EOF'
packageConfiguration:
  version: v1
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

@test "composes ordered inputs before migration and preserves canonical precedence" {
  OVERLAY_FILE="${BATS_TEST_TMPDIR}/production.yaml"
  cat >"$INPUT_FILE" <<'EOF'
packageConfiguration:
  version: v1
packages:
  kiali:
    enabled: false
    flux:
      interval: 5m
compositionTest:
  entries:
    - base-one
    - base-two
EOF
  cat >"$OVERLAY_FILE" <<'EOF'
kiali:
  enabled: true
  flux:
    timeout: 10m
domain: production.bigbang.mil
compositionTest:
  entries:
    - production
EOF

  run "$SCRIPT_PATH" -o "$OUTPUT_FILE" "$INPUT_FILE" "$OVERLAY_FILE"

  [ "$status" -eq 0 ]
  [ "$(yq '.packages.kiali.enabled' "$OUTPUT_FILE")" = "false" ]
  [ "$(yq '.packages.kiali.flux.interval' "$OUTPUT_FILE")" = "5m" ]
  [ "$(yq '.packages.kiali.flux.timeout' "$OUTPUT_FILE")" = "10m" ]
  [ "$(yq '.domain' "$OUTPUT_FILE")" = "production.bigbang.mil" ]
  [ "$(yq -o=json -I=0 '.compositionTest.entries' "$OUTPUT_FILE")" = '["production"]' ]
  [ "$(yq 'has("kiali")' "$OUTPUT_FILE")" = "false" ]
}

@test "migrates both mattermost operator spellings with documented precedence" {
  cat >"$INPUT_FILE" <<'EOF'
packageConfiguration:
  version: v1
addons:
  mattermostoperator:
    enabled: true
    flux:
      interval: 5m
      timeout: 5m
  mattermostOperator:
    enabled: false
    flux:
      timeout: 10m
packages:
  mattermostOperator:
    flux:
      timeout: 20m
EOF

  run "$SCRIPT_PATH" -o "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [ "$(yq '.packages.mattermostOperator.enabled' "$OUTPUT_FILE")" = "false" ]
  [ "$(yq '.packages.mattermostOperator.flux.interval' "$OUTPUT_FILE")" = "5m" ]
  [ "$(yq '.packages.mattermostOperator.flux.timeout' "$OUTPUT_FILE")" = "20m" ]
  [ "$(yq '.addons | has("mattermostoperator")' "$OUTPUT_FILE")" = "false" ]
  [ "$(yq '.addons | has("mattermostOperator")' "$OUTPUT_FILE")" = "false" ]
}

@test "refuses to reinterpret an existing custom package with a built-in name" {
  cat >"$INPUT_FILE" <<'EOF'
packages:
  kiali:
    enabled: true
    sourceType: git
    git:
      repo: https://example.com/custom-kiali.git
      path: chart
      tag: v1
EOF

  run "$SCRIPT_PATH" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"packages.kiali is an existing 3.x custom package"* ]]
}

@test "rejects a custom package whose normalized identity matches a built-in" {
  cat >"$INPUT_FILE" <<'EOF'
packages:
  istio-cni:
    enabled: true
EOF

  run "$SCRIPT_PATH" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"packages.istio-cni conflicts with built-in package packages.istioCNI"* ]]
}

@test "rejects custom packages that normalize to the same identity" {
  cat >"$INPUT_FILE" <<'EOF'
packageConfiguration:
  version: v1
packages:
  examplePackage:
    enabled: true
  example-package:
    enabled: false
EOF

  run "$SCRIPT_PATH" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"packages.examplePackage and packages.example-package normalize to the same package identity"* ]]
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
  [ "$(yq '.packageConfiguration.version' "$INPUT_FILE")" = "v1" ]
}

@test "migrates values in a decrypted Secret stringData key" {
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: environment
  namespace: bigbang
stringData:
  values.yaml: |
    monitoring:
      enabled: true
    addons:
      gitlab:
        enabled: false
  unrelated: preserve-me
EOF

  run "$SCRIPT_PATH" --secret-key values.yaml --output "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [ "$(yq '.metadata.name' "$OUTPUT_FILE")" = "environment" ]
  [ "$(yq '.metadata.namespace' "$OUTPUT_FILE")" = "bigbang" ]
  [ "$(yq '.stringData.unrelated' "$OUTPUT_FILE")" = "preserve-me" ]
  [ "$(yq -r '.stringData."values.yaml"' "$OUTPUT_FILE" | yq '.packageConfiguration.version' -)" = "v1" ]
  [ "$(yq -r '.stringData."values.yaml"' "$OUTPUT_FILE" | yq '.packages.monitoring.enabled' -)" = "true" ]
  [ "$(yq -r '.stringData."values.yaml"' "$OUTPUT_FILE" | yq '.packages.gitlab.enabled' -)" = "false" ]

  SECOND_OUTPUT_FILE="${BATS_TEST_TMPDIR}/secret-4.x-second.yaml"
  run "$SCRIPT_PATH" --secret-key values.yaml \
    --output "$SECOND_OUTPUT_FILE" "$OUTPUT_FILE"

  [ "$status" -eq 0 ]
  cmp "$OUTPUT_FILE" "$SECOND_OUTPUT_FILE"
}

@test "migrates base64 values in a decrypted Secret data key" {
  printf '%s\n' 'kiali:' '  enabled: true' >"${BATS_TEST_TMPDIR}/plain-values.yaml"
  base64 <"${BATS_TEST_TMPDIR}/plain-values.yaml" | tr -d '\n' >"${BATS_TEST_TMPDIR}/encoded-values"
  ENCODED_VALUES_FILE="${BATS_TEST_TMPDIR}/encoded-values" yq -n '
    .apiVersion = "v1" |
    .kind = "Secret" |
    .metadata.name = "environment" |
    .data."bigbang.yaml" = load_str(strenv(ENCODED_VALUES_FILE))
  ' >"$INPUT_FILE"

  run "$SCRIPT_PATH" --secret-key bigbang.yaml --output "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ]
  yq -r '.data."bigbang.yaml"' "$OUTPUT_FILE" \
    | base64 --decode >"${BATS_TEST_TMPDIR}/migrated-values.yaml"
  [ "$(yq '.packageConfiguration.version' "${BATS_TEST_TMPDIR}/migrated-values.yaml")" = "v1" ]
  [ "$(yq '.packages.kiali.enabled' "${BATS_TEST_TMPDIR}/migrated-values.yaml")" = "true" ]
}

@test "automatically expands and reports anchors in decrypted Secret values" {
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: environment
stringData:
  values.yaml: |
    addons:
      keycloak:
        enabled: true
        values:
          testPassword: &testPassword placeholder
          copiedPassword: *testPassword
EOF

  run --separate-stderr "$SCRIPT_PATH" --secret-key values.yaml \
    --output "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [[ "$stderr" == *"Warning: expanded YAML anchors and aliases"* ]]
  [[ "$stderr" == *"Expanded anchors:"* ]]
  [[ "$stderr" == *"testPassword"* ]]
  printf '%s' "$(yq -r '.stringData."values.yaml"' "$OUTPUT_FILE")" \
    >"${BATS_TEST_TMPDIR}/expanded-values.yaml"
  [ "$(yq '.packages.keycloak.values.testPassword' "${BATS_TEST_TMPDIR}/expanded-values.yaml")" = "placeholder" ]
  [ "$(yq '.packages.keycloak.values.copiedPassword' "${BATS_TEST_TMPDIR}/expanded-values.yaml")" = "placeholder" ]
  [ "$(yq '[.. | anchor] | map(select(. != "")) | length' "${BATS_TEST_TMPDIR}/expanded-values.yaml")" = "0" ]
  [ "$(yq '[.. | select(kind == "alias")] | length' "${BATS_TEST_TMPDIR}/expanded-values.yaml")" = "0" ]
}

@test "decrypted Secret mode creates a backup in place" {
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: environment
stringData:
  values.yaml: |
    grafana:
      enabled: true
EOF

  run "$SCRIPT_PATH" --secret-key values.yaml --in-place "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [ -f "${INPUT_FILE}.bak" ]
  [ "$(yq -r '.stringData."values.yaml"' "${INPUT_FILE}.bak" | yq '.grafana.enabled' -)" = "true" ]
  [ "$(yq -r '.stringData."values.yaml"' "$INPUT_FILE" | yq '.packages.grafana.enabled' -)" = "true" ]
}

@test "decrypted Secret mode rejects unsafe envelope inputs" {
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: ConfigMap
data:
  values.yaml: bW9uaXRvcmluZzoKICBlbmFibGVkOiB0cnVlCg==
EOF

  run "$SCRIPT_PATH" --secret-key values.yaml "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"must be a Kubernetes Secret"* ]]

  cat >"$INPUT_FILE" <<'EOF'
apiVersion: v1
kind: Secret
data:
  values.yaml: not-base64!
EOF

  run "$SCRIPT_PATH" --secret-key values.yaml "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"data.values.yaml is not valid base64"* ]]
}

@test "decrypted Secret mode requires exactly one input" {
  OVERLAY_FILE="${BATS_TEST_TMPDIR}/other-secret.yaml"
  printf '%s\n' 'kind: Secret' >"$INPUT_FILE"
  printf '%s\n' 'kind: Secret' >"$OVERLAY_FILE"

  run "$SCRIPT_PATH" --secret-key values.yaml "$INPUT_FILE" "$OVERLAY_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"--secret-key requires exactly one input Secret"* ]]
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

@test "rejects an unsupported package configuration version" {
  cat >"$INPUT_FILE" <<'EOF'
packageConfiguration:
  version: v2
EOF

  run "$SCRIPT_PATH" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"packageConfiguration.version must be v1"* ]]
}

@test "rejects SOPS-encrypted input with remediation guidance" {
  cat >"$INPUT_FILE" <<'EOF'
kiali:
  enabled: ENC[AES256_GCM,data:abc,type:bool]
sops:
  mac: ENC[AES256_GCM,data:def,type:str]
  version: 3.9.0
EOF

  run "$SCRIPT_PATH" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"SOPS-encrypted input is not supported"* ]]
  [[ "$output" == *"use scripts/migrate-sops-values-3-to-4.sh"* ]]
}

@test "rejects multi-document YAML" {
  cat >"$INPUT_FILE" <<'EOF'
kiali:
  enabled: true
---
monitoring:
  enabled: true
EOF

  run "$SCRIPT_PATH" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"multiple YAML documents are not supported"* ]]
}

@test "automatically expands and reports YAML anchors and aliases" {
  cat >"$INPUT_FILE" <<'EOF'
defaults: &packageDefaults
  enabled: true
kiali:
  <<: *packageDefaults
EOF

  run --separate-stderr "$SCRIPT_PATH" --output "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [[ "$stderr" == *"Warning: expanded YAML anchors and aliases"* ]]
  [[ "$stderr" == *"Expanded anchors:"* ]]
  [[ "$stderr" == *"packageDefaults"* ]]
  [ "$(yq '.packages.kiali.enabled' "$OUTPUT_FILE")" = "true" ]
  [ "$(yq '[.. | anchor] | map(select(. != "")) | length' "$OUTPUT_FILE")" = "0" ]
  [ "$(yq '[.. | select(kind == "alias")] | length' "$OUTPUT_FILE")" = "0" ]
}

@test "fails if automatic anchor expansion changes the resolved structure" {
  FAKE_BIN="${BATS_TEST_TMPDIR}/fake-bin"
  mkdir "$FAKE_BIN"
  cat >"${FAKE_BIN}/cmp" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
  chmod +x "${FAKE_BIN}/cmp"
  cat >"$INPUT_FILE" <<'EOF'
defaults: &packageDefaults
  enabled: true
kiali: *packageDefaults
EOF

  run env PATH="${FAKE_BIN}:${PATH}" "$SCRIPT_PATH" \
    --output "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"expanding YAML anchors changed the resolved values structure"* ]]
  [ ! -e "$OUTPUT_FILE" ]
}

@test "rejects output symlinks and hardlinks that refer to the input" {
  SYMLINK_OUTPUT="${BATS_TEST_TMPDIR}/values-symlink.yaml"
  HARDLINK_OUTPUT="${BATS_TEST_TMPDIR}/values-hardlink.yaml"
  cat >"$INPUT_FILE" <<'EOF'
kiali:
  enabled: true
EOF
  cp "$INPUT_FILE" "${INPUT_FILE}.original"
  ln -s "$INPUT_FILE" "$SYMLINK_OUTPUT"

  run "$SCRIPT_PATH" -o "$SYMLINK_OUTPUT" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"output refers to an input file"* ]]
  cmp "$INPUT_FILE" "${INPUT_FILE}.original"

  ln "$INPUT_FILE" "$HARDLINK_OUTPUT"
  run "$SCRIPT_PATH" -o "$HARDLINK_OUTPUT" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"output refers to an input file"* ]]
  cmp "$INPUT_FILE" "${INPUT_FILE}.original"
}

@test "rejects a directory as the output path" {
  OUTPUT_DIRECTORY="${BATS_TEST_TMPDIR}/output"
  mkdir "$OUTPUT_DIRECTORY"
  cat >"$INPUT_FILE" <<'EOF'
kiali:
  enabled: true
EOF

  run "$SCRIPT_PATH" --output "$OUTPUT_DIRECTORY" "$INPUT_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"output path must be a file, not a directory"* ]]
  [ -z "$(find "$OUTPUT_DIRECTORY" -mindepth 1 -maxdepth 1 -print -quit)" ]
}

@test "rejects in-place mode with multiple inputs" {
  OVERLAY_FILE="${BATS_TEST_TMPDIR}/production.yaml"
  printf '%s\n' 'domain: dev.bigbang.mil' >"$INPUT_FILE"
  printf '%s\n' 'domain: production.bigbang.mil' >"$OVERLAY_FILE"

  run "$SCRIPT_PATH" --in-place "$INPUT_FILE" "$OVERLAY_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"--in-place requires exactly one input file"* ]]
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

#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT=$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)
  SCRIPT_PATH="${REPO_ROOT}/scripts/migrate-values-3-to-4.sh"
  INPUT_FILE="${BATS_TEST_TMPDIR}/patch.yaml"
  OUTPUT_FILE="${BATS_TEST_TMPDIR}/values-4.x.yaml"
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: monitoring
  namespace: bigbang
spec:
  interval: 10m
  timeout: 20m
  upgrade:
    remediation:
      retries: 3
  values:
    upstream:
      prometheus:
        prometheusSpec:
          retention: 15d
EOF
}

@test "converts a package patch to values without changing the input" {
  cp "$INPUT_FILE" "${INPUT_FILE}.original"
  run "$SCRIPT_PATH" --helmrelease-patch "$INPUT_FILE" -o "$OUTPUT_FILE"

  [ "$status" -eq 0 ]
  [ "$(yq '.packageConfiguration.version' "$OUTPUT_FILE")" = v1 ]
  [ "$(yq '.packages.monitoring.flux.timeout' "$OUTPUT_FILE")" = 20m ]
  [ "$(yq '.packages.monitoring.flux.upgrade.remediation.retries' "$OUTPUT_FILE")" = 3 ]
  [ "$(yq '.packages.monitoring.values.upstream.prometheus.prometheusSpec.retention' "$OUTPUT_FILE")" = 15d ]
  [ "$(yq 'has("kind") or has("spec") or (.packages.monitoring | has("enabled"))' "$OUTPUT_FILE")" = false ]
  cmp "$INPUT_FILE" "${INPUT_FILE}.original"

  run "$SCRIPT_PATH" -o "${OUTPUT_FILE}.second" "$OUTPUT_FILE"
  [ "$status" -eq 0 ]
  cmp "$OUTPUT_FILE" "${OUTPUT_FILE}.second"

  run helm lint "${REPO_ROOT}/chart" -f "$OUTPUT_FILE"
  [ "$status" -eq 0 ]
}

@test "patches override migrated raw values and later patches win recursively" {
  RAW_VALUES="${BATS_TEST_TMPDIR}/base.yaml"
  SECOND_PATCH="${BATS_TEST_TMPDIR}/second-patch.yaml"
  cat >"$RAW_VALUES" <<'EOF'
packageConfiguration:
  version: v1
packages:
  monitoring:
    flux:
      timeout: 5m
    values:
      entries: [base-one, base-two]
      keep: true
monitoring:
  enabled: true
  flux:
    test:
      enable: false
EOF
  cp "$INPUT_FILE" "$SECOND_PATCH"
  yq -i '.spec = {"timeout": "30m", "values": {"entries": ["patch"]}}' "$SECOND_PATCH"

  run "$SCRIPT_PATH" --helmrelease-patch "$INPUT_FILE" "$RAW_VALUES" \
    --helmrelease-patch "$SECOND_PATCH" -o "$OUTPUT_FILE"

  [ "$status" -eq 0 ]
  [ "$(yq '.packages.monitoring.enabled' "$OUTPUT_FILE")" = true ]
  [ "$(yq '.packages.monitoring.flux.timeout' "$OUTPUT_FILE")" = 30m ]
  [ "$(yq '.packages.monitoring.flux.interval' "$OUTPUT_FILE")" = 10m ]
  [ "$(yq '.packages.monitoring.flux.test.enable' "$OUTPUT_FILE")" = false ]
  [ "$(yq '.packages.monitoring.values.keep' "$OUTPUT_FILE")" = true ]
  [ "$(yq '.packages.monitoring.values.upstream.prometheus.prometheusSpec.retention' "$OUTPUT_FILE")" = 15d ]
  [ "$(yq -o=json -I=0 '.packages.monitoring.values.entries' "$OUTPUT_FILE")" = '["patch"]' ]
}

@test "converts multiple patch documents and maps HelmRelease names to canonical keys" {
  cat >>"$INPUT_FILE" <<'EOF'
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: ek
spec:
  values:
    kibana:
      count: 2
---
apiVersion: helm.toolkit.fluxcd.io/v2beta2
kind: HelmRelease
metadata:
  name: gitlab-runner
spec:
  suspend: false
EOF
  run "$SCRIPT_PATH" --omit-package-configuration --helmrelease-patch "$INPUT_FILE" -o "$OUTPUT_FILE"

  [ "$status" -eq 0 ]
  [ "$(yq 'has("packageConfiguration")' "$OUTPUT_FILE")" = false ]
  [ "$(yq '.packages.elasticsearchKibana.values.kibana.count' "$OUTPUT_FILE")" = 2 ]
  [ "$(yq '.packages.gitlabRunner.flux.suspend' "$OUTPUT_FILE")" = false ]
  [ "$(yq '.packages.elasticsearchKibana | has("flux")' "$OUTPUT_FILE")" = false ]
  [ "$(yq '.packages.gitlabRunner | has("values")' "$OUTPUT_FILE")" = false ]
  [ "$(yq -o=json -I=0 '.packages | keys' "$OUTPUT_FILE")" = '["monitoring","elasticsearchKibana","gitlabRunner"]' ]
}

@test "reports and expands anchors in package patches" {
  yq -i '.spec.install = .spec.upgrade | .spec.upgrade anchor = "remediation" | .spec.install alias = "remediation"' "$INPUT_FILE"

  run "$SCRIPT_PATH" --helmrelease-patch "$INPUT_FILE" -o "$OUTPUT_FILE"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Expanded anchors:"* ]]
  [ "$(yq '.packages.monitoring.flux.install.remediation.retries' "$OUTPUT_FILE")" = 3 ]
}

@test "refuses ambiguous package identities and parent HelmReleases" {
  for release_name in bigbang custom-package public-ingressgateway istio-gateway; do
    RELEASE_NAME="$release_name" yq -i '.metadata.name = strenv(RELEASE_NAME)' "$INPUT_FILE"
    run "$SCRIPT_PATH" --helmrelease-patch "$INPUT_FILE" -o "$OUTPUT_FILE"
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot identify a built-in package"* ]]
    [ ! -e "$OUTPUT_FILE" ]
  done
}

@test "rejects unsupported fields without leaking values or writing partial output" {
  printf 'existing output\n' >"$OUTPUT_FILE"
  for field in chart valuesFrom dependsOn postRenderers targetNamespace; do
    PATCH_FIELD="$field" yq -i '.spec[strenv(PATCH_FIELD)] = "private-test-sentinel"' "$INPUT_FILE"
    run "$SCRIPT_PATH" --helmrelease-patch "$INPUT_FILE" -o "$OUTPUT_FILE"
    [ "$status" -ne 0 ]
    [[ "$output" == *"unsupported HelmRelease patch fields"* ]]
    [[ "$output" != *"private-test-sentinel"* ]]
    [ "$(cat "$OUTPUT_FILE")" = "existing output" ]
    PATCH_FIELD="$field" yq -i 'del(.spec[strenv(PATCH_FIELD)])' "$INPUT_FILE"
  done

  yq -i '.metadata.annotations.owner = "private-test-sentinel"' "$INPUT_FILE"
  run "$SCRIPT_PATH" --helmrelease-patch "$INPUT_FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"metadata.annotations"* ]]
  [[ "$output" != *"private-test-sentinel"* ]]
}

@test "rejects null deletions and nested Kustomize patch directives" {
  for expression in '.spec.values.upstream = null' '.spec.values.upstream.$patch = "replace"'; do
    EXPRESSION="$expression" yq -i 'eval(strenv(EXPRESSION))' "$INPUT_FILE"
    run "$SCRIPT_PATH" --helmrelease-patch "$INPUT_FILE" -o "$OUTPUT_FILE"
    [ "$status" -ne 0 ]
    [[ "$output" == *"null deletions and patch directives require manual migration"* ]]
    [ ! -e "$OUTPUT_FILE" ]
  done
}

@test "rejects malformed encrypted and non-HelmRelease patch documents" {
  for expression in '.spec.values = []' '.apiVersion = "example.com/v1"' '.kind = "Secret"' '.sops = {"encrypted": true}' '.spec = "invalid"' '.metadata.name = null'; do
    cp "$INPUT_FILE" "${INPUT_FILE}.invalid"
    EXPRESSION="$expression" yq -i 'eval(strenv(EXPRESSION))' "${INPUT_FILE}.invalid"
    run "$SCRIPT_PATH" --helmrelease-patch "${INPUT_FILE}.invalid" -o "$OUTPUT_FILE"
    [ "$status" -ne 0 ]
    [ ! -e "$OUTPUT_FILE" ]
  done

  printf 'invalid: [\n' >"${INPUT_FILE}.invalid"
  run "$SCRIPT_PATH" --helmrelease-patch "${INPUT_FILE}.invalid" -o "$OUTPUT_FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not valid YAML"* ]]
}

@test "a later invalid document prevents any converted output" {
  cat >>"$INPUT_FILE" <<'EOF'
---
- op: replace
  path: /spec/timeout
  value: 30m
EOF
  run --separate-stderr "$SCRIPT_PATH" --helmrelease-patch "$INPUT_FILE" -o "$OUTPUT_FILE"

  [ "$status" -ne 0 ]
  [ -z "$output" ]
  [ ! -e "$OUTPUT_FILE" ]
}

@test "HelmRelease inputs require the explicit patch option" {
  run "$SCRIPT_PATH" "$INPUT_FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"use --helmrelease-patch"* ]]
}

@test "works with system Bash for patches-only and values-only inputs" {
  run /bin/bash "$SCRIPT_PATH" --helmrelease-patch "$INPUT_FILE" -o "$OUTPUT_FILE"
  [ "$status" -eq 0 ]
  run /bin/bash "$SCRIPT_PATH" "$OUTPUT_FILE" -o "${OUTPUT_FILE}.second"
  [ "$status" -eq 0 ]
  cmp "$OUTPUT_FILE" "${OUTPUT_FILE}.second"
}

@test "patch mode protects input paths and rejects incompatible options" {
  run "$SCRIPT_PATH" --helmrelease-patch "$INPUT_FILE" --in-place
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot be combined with --in-place"* ]]
  [ ! -e "${INPUT_FILE}.bak" ]

  run "$SCRIPT_PATH" --helmrelease-patch "$INPUT_FILE" --secret-key values.yaml "$INPUT_FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot be combined with --secret-key"* ]]

  ln -s "$INPUT_FILE" "$OUTPUT_FILE"
  run "$SCRIPT_PATH" --helmrelease-patch "$INPUT_FILE" -o "$OUTPUT_FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"output refers to an input file"* ]]

  run "$SCRIPT_PATH" --helmrelease-patch
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires a file path"* ]]
}

#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT=$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)
  SCRIPT_PATH="${REPO_ROOT}/scripts/migrate-values-3-to-4.sh"
  INPUT_FILE="${BATS_TEST_TMPDIR}/bigbang-patch.yaml"
  OUTPUT_FILE="${BATS_TEST_TMPDIR}/bigbang-4.x.yaml"
  cat >"$INPUT_FILE" <<'EOF'
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: bigbang
  namespace: bigbang
  annotations:
    example.com/owner: platform
spec:
  interval: 5m
  chart:
    spec:
      chart: chart
      sourceRef:
        kind: GitRepository
        name: bigbang
  valuesFrom:
    - kind: Secret
      name: environment-values
  postRenderers:
    - kustomize:
        patches:
          - target:
              kind: NetworkPolicy
              name: example
            patch: |
              $patch: delete
              apiVersion: networking.k8s.io/v1
              kind: NetworkPolicy
              metadata:
                name: example
  values:
    domain: example.test
    monitoring:
      enabled: true
      values:
        upstream:
          resources:
            limits:
              cpu: null
    addons:
      argocd:
        enabled: true
        values:
          projects:
            ${cluster_name}:
              enabled: true
        postRenderers:
          - kustomize:
              patches:
                - target:
                    kind: ConfigMap
                    name: example
                  patch: |
                    $patch: delete
                    apiVersion: v1
                    kind: ConfigMap
                    metadata:
                      name: example
EOF
}

@test "migrates parent inline values and preserves the complete surrounding manifest" {
  cp "$INPUT_FILE" "${INPUT_FILE}.original"
  run "$SCRIPT_PATH" --bigbang-helmrelease -o "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [ "$(yq '.spec.values.packageConfiguration.version' "$OUTPUT_FILE")" = v1 ]
  [ "$(yq '.spec.values.packages.monitoring.enabled' "$OUTPUT_FILE")" = true ]
  [ "$(yq '.spec.values.packages.argocd.enabled' "$OUTPUT_FILE")" = true ]
  [ "$(yq '.spec.values.domain' "$OUTPUT_FILE")" = example.test ]
  [ "$(yq '.spec.values | has("monitoring") or has("addons")' "$OUTPUT_FILE")" = false ]
  [ "$(yq -o=json -I=0 'del(.spec.values)' "$OUTPUT_FILE")" \
    = "$(yq -o=json -I=0 'del(.spec.values)' "$INPUT_FILE")" ]
  [ "$(yq -o=json -I=0 '.spec.values.packages.monitoring' "$OUTPUT_FILE")" \
    = "$(yq -o=json -I=0 '.spec.values.monitoring' "$INPUT_FILE")" ]
  [ "$(yq -o=json -I=0 '.spec.values.packages.argocd' "$OUTPUT_FILE")" \
    = "$(yq -o=json -I=0 '.spec.values.addons.argocd' "$INPUT_FILE")" ]
  cmp "$INPUT_FILE" "${INPUT_FILE}.original"

  run "$SCRIPT_PATH" --bigbang-helmrelease -o "${OUTPUT_FILE}.second" "$OUTPUT_FILE"
  [ "$status" -eq 0 ]
  cmp "$OUTPUT_FILE" "${OUTPUT_FILE}.second"
}

@test "secondary parent patches omit the discriminator and stay idempotent" {
  run "$SCRIPT_PATH" --bigbang-helmrelease --omit-package-configuration \
    -o "$OUTPUT_FILE" "$INPUT_FILE"
  [ "$status" -eq 0 ]
  [ "$(yq '.spec.values | has("packageConfiguration")' "$OUTPUT_FILE")" = false ]

  run /bin/bash "$SCRIPT_PATH" --bigbang-helmrelease --omit-package-configuration \
    -o "${OUTPUT_FILE}.second" "$OUTPUT_FILE"
  [ "$status" -eq 0 ]
  cmp "$OUTPUT_FILE" "${OUTPUT_FILE}.second"
}

@test "parent migration preserves canonical precedence and unrelated custom packages" {
  yq -i '.spec.values.packageConfiguration.version = "v1" |
    .spec.values.packages.monitoring.enabled = false |
    .spec.values.packages.podinfo.enabled = true |
    .spec.values.addons.mattermostoperator.enabled = true' "$INPUT_FILE"
  run "$SCRIPT_PATH" --bigbang-helmrelease -o "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [ "$(yq '.spec.values.packages.monitoring.enabled' "$OUTPUT_FILE")" = false ]
  [ "$(yq '.spec.values.packages.podinfo.enabled' "$OUTPUT_FILE")" = true ]
  [ "$(yq '.spec.values.packages.mattermostOperator.enabled' "$OUTPUT_FILE")" = true ]
  [ "$(yq '.spec.values.packages.monitoring.values.upstream.resources.limits | has("cpu")' "$OUTPUT_FILE")" = true ]
  [ "$(yq '.spec.values.packages.monitoring.values.upstream.resources.limits.cpu | tag' "$OUTPUT_FILE")" = '!!null' ]
}

@test "in-place parent migration creates a backup and refuses to overwrite it" {
  cp "$INPUT_FILE" "${INPUT_FILE}.original"
  run "$SCRIPT_PATH" --bigbang-helmrelease --in-place "$INPUT_FILE"
  [ "$status" -eq 0 ]
  cmp "${INPUT_FILE}.bak" "${INPUT_FILE}.original"
  [ "$(yq '.spec.values.packages.monitoring.enabled' "$INPUT_FILE")" = true ]

  cp "$INPUT_FILE" "${INPUT_FILE}.migrated"
  run "$SCRIPT_PATH" --bigbang-helmrelease --in-place "$INPUT_FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"backup already exists"* ]]
  cmp "$INPUT_FILE" "${INPUT_FILE}.migrated"
}

@test "parent patches without inline values remain byte-for-byte unchanged" {
  yq -i 'del(.spec.values)' "$INPUT_FILE"
  run "$SCRIPT_PATH" --bigbang-helmrelease -o "$OUTPUT_FILE" "$INPUT_FILE"
  [ "$status" -eq 0 ]
  cmp "$INPUT_FILE" "$OUTPUT_FILE"
  [ "$(yq '.spec | has("values")' "$OUTPUT_FILE")" = false ]
}

@test "expands envelope anchors before extracting inline values" {
  yq -i '.metadata.annotations."example.com/shared" = "example.test" |
    .metadata.annotations."example.com/shared" anchor = "domain" |
    .spec.values.domain alias = "domain"' "$INPUT_FILE"
  run "$SCRIPT_PATH" --bigbang-helmrelease -o "$OUTPUT_FILE" "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Expanded anchors:"* ]]
  [ "$(yq '.spec.values.domain' "$OUTPUT_FILE")" = example.test ]
  [ "$(yq '.metadata.annotations."example.com/shared"' "$OUTPUT_FILE")" = example.test ]
}

@test "accepts Flux versions and an explicitly selected renamed parent release" {
  for api_version in v2 v2beta2 v2beta1; do
    API_VERSION="$api_version" yq -i '.apiVersion = "helm.toolkit.fluxcd.io/" + strenv(API_VERSION) |
      .metadata.name = "platform"' "$INPUT_FILE"
    run "$SCRIPT_PATH" --bigbang-helmrelease -o "$OUTPUT_FILE" "$INPUT_FILE"
    [ "$status" -eq 0 ]
    [ "$(yq '.apiVersion' "$OUTPUT_FILE")" = "helm.toolkit.fluxcd.io/$api_version" ]
    [ "$(yq '.metadata.name' "$OUTPUT_FILE")" = platform ]
  done
}

@test "parent mode rejects malformed encrypted and multi-document inputs without output" {
  for expression in '.spec.values = []' '.spec.values = null' '.spec = null' '.kind = "Secret"' '.apiVersion = "example.com/v1"' '.metadata.name = null' '.sops = {}' '.spec.values.packages = []'; do
    cp "$INPUT_FILE" "${INPUT_FILE}.invalid"
    EXPRESSION="$expression" yq -i 'eval(strenv(EXPRESSION))' "${INPUT_FILE}.invalid"
    run "$SCRIPT_PATH" --bigbang-helmrelease -o "$OUTPUT_FILE" "${INPUT_FILE}.invalid"
    [ "$status" -ne 0 ]
    [ ! -e "$OUTPUT_FILE" ]
  done

  cat "$INPUT_FILE" >"${INPUT_FILE}.invalid"
  printf '\n---\n' >>"${INPUT_FILE}.invalid"
  cat "$INPUT_FILE" >>"${INPUT_FILE}.invalid"
  run "$SCRIPT_PATH" --bigbang-helmrelease -o "$OUTPUT_FILE" "${INPUT_FILE}.invalid"
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires exactly one YAML document"* ]]
  [ ! -e "$OUTPUT_FILE" ]
}

@test "parent mode refuses package-map deletions and structural patch directives" {
  for expression in '.spec.values.monitoring = null' '.spec.values.addons.argocd = null' '.spec.values.addons.mattermostoperator = null' '.spec.values.packages = null' '.spec.values.packageConfiguration.version = "v1" | .spec.values.packages.monitoring = null' '.spec.values.monitoring.$patch = "replace"'; do
    cp "$INPUT_FILE" "${INPUT_FILE}.invalid"
    EXPRESSION="$expression" yq -i 'eval(strenv(EXPRESSION))' "${INPUT_FILE}.invalid"
    run "$SCRIPT_PATH" --bigbang-helmrelease -o "$OUTPUT_FILE" "${INPUT_FILE}.invalid"
    [ "$status" -ne 0 ]
    [[ "$output" == *"require manual migration"* ]]
    [ ! -e "$OUTPUT_FILE" ]
  done
}

@test "parent mode retains the existing custom-package collision safeguard" {
  yq -i '.spec.values.packages.monitoring.enabled = false' "$INPUT_FILE"
  run "$SCRIPT_PATH" --bigbang-helmrelease -o "$OUTPUT_FILE" "$INPUT_FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"existing 3.x custom package"* ]]
  [ ! -e "$OUTPUT_FILE" ]
}

@test "parent mode rejects incompatible options and unsafe output targets" {
  run "$SCRIPT_PATH" --bigbang-helmrelease "$INPUT_FILE" "$INPUT_FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires exactly one input"* ]]

  run "$SCRIPT_PATH" --bigbang-helmrelease --secret-key values.yaml "$INPUT_FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot be combined"* ]]

  run "$SCRIPT_PATH" --bigbang-helmrelease --helmrelease-patch "$INPUT_FILE" "$INPUT_FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot be combined"* ]]

  ln "$INPUT_FILE" "$OUTPUT_FILE"
  run "$SCRIPT_PATH" --bigbang-helmrelease -o "$OUTPUT_FILE" "$INPUT_FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"output refers to an input file"* ]]
}

@test "migrated parent overlays compose through Kustomize and render with Big Bang" {
  run "$SCRIPT_PATH" --bigbang-helmrelease -o "$OUTPUT_FILE" "$INPUT_FILE"
  [ "$status" -eq 0 ]
  yq -i '.spec.values = {}' "$INPUT_FILE"
  cat >"${BATS_TEST_TMPDIR}/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - bigbang-patch.yaml
patches:
  - path: bigbang-4.x.yaml
EOF
  kubectl kustomize "$BATS_TEST_TMPDIR" >"${BATS_TEST_TMPDIR}/rendered.yaml"
  [ "$(yq '.spec.values.packages.argocd.enabled' "${BATS_TEST_TMPDIR}/rendered.yaml")" = true ]
  [ "$(yq -o=json '.spec.postRenderers' "${BATS_TEST_TMPDIR}/rendered.yaml" | jq -cS .)" \
    = "$(yq -o=json '.spec.postRenderers' "$OUTPUT_FILE" | jq -cS .)" ]

  # Use a representative package patch with chart-valid values for rendering;
  # the fixture's arbitrary workload values above exercise lossless migration.
  yq '.spec.values | del(.packages.argocd) |
    .packages.monitoring.values = {}' "$OUTPUT_FILE" >"${BATS_TEST_TMPDIR}/values.yaml"
  run helm template bigbang "${REPO_ROOT}/chart" -f "${BATS_TEST_TMPDIR}/values.yaml" \
    --kube-version 1.35.0 --show-only templates/monitoring/helmrelease.yaml
  [ "$status" -eq 0 ]
  [[ "$output" == *"name: monitoring"* ]]
}

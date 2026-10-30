#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT=$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)
  SCRIPT_PATH="${REPO_ROOT}/scripts/migrate-values-3-to-4.sh"
  FIXTURES="${BATS_TEST_DIRNAME}/fixtures/istio-hosts"
  INPUT_FILE="${BATS_TEST_TMPDIR}/input.yaml"
  OUTPUT_FILE="${BATS_TEST_TMPDIR}/output.yaml"
}

assert_yaml_equal() {
  diff -u <(yq -o=json '.' "$1" | jq -S '.') \
    <(yq -o=json '.' "$2" | jq -S '.')
}

assert_fixture() {
  local fixture=$1
  cp "$FIXTURES/$fixture/input.yaml" "$INPUT_FILE"
  run --separate-stderr "$SCRIPT_PATH" --target 4 -o "$OUTPUT_FILE" "$INPUT_FILE"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  assert_yaml_equal "$FIXTURES/$fixture/expected.yaml" "$OUTPUT_FILE"
  cmp "$FIXTURES/$fixture/input.yaml" "$INPUT_FILE"

  run --separate-stderr "$SCRIPT_PATH" --target 4 -o "${OUTPUT_FILE}.second" "$OUTPUT_FILE"
  [ "$status" -eq 0 ]
  cmp "$OUTPUT_FILE" "${OUTPUT_FILE}.second"
}

@test "converts the release environment Tempo hostname override" {
  assert_fixture tempo-release
  [[ "$stderr" == *"No legacy built-in package paths found."* ]]
}

@test "converts package-level hosts from root addon and canonical package paths" {
  assert_fixture package-level
}

@test "maps every supported historical endpoint without mixing host lists" {
  assert_fixture endpoint-mappings
}

@test "preserves explicit canonical route hosts including empty and null hosts" {
  assert_fixture canonical-conflicts
}

@test "converts relocated hosts preserving siblings route fields and literal strings" {
  assert_fixture route-fields
}

@test "translates domain templates and preserves unsupported templates for review" {
  assert_fixture host-templates
  [[ "$stderr" == *"packages.monitoring.values.bb-common.istio.prometheus.hosts: unsupported Helm template; hosts preserved"* ]]
  [[ "$stderr" == *"packages.monitoring.istio.prometheus.hosts: a higher-precedence legacy hostname override requires manual template migration"* ]]
  [[ "$stderr" == *"packages.argocd.values.bb-common.istio.argocd.hosts: the package does not expose the umbrella domain"* ]]
  [[ "$stderr" == *"packages.minio.values.bb-common.istio.api.hosts: the package does not expose the umbrella domain"* ]]
  [[ "$stderr" != *"packages.kiali.values.bb-common.istio.kiali.hosts: unsupported"* ]]
  [[ "$stderr" != *"customDomain"* ]]
}

@test "preserves domain templates with an explicit package domain for manual review" {
  assert_fixture package-domain
  [[ "$stderr" == *"packages.tempo.values.domain"*"hosts preserved"* ]]
}

@test "package domain does not block literal or canonical hostname overrides" {
  yq '.tempo.values.istio.tempoQuery.hosts = ["literal.example.test"]' \
    "$FIXTURES/package-domain/input.yaml" >"$INPUT_FILE"
  run --separate-stderr "$SCRIPT_PATH" --target 4 -o "$OUTPUT_FILE" "$INPUT_FILE"
  [ "$status" -eq 0 ]
  [ "$(yq '.packages.tempo.values.bb-common.routes.inbound.tempo-query.hosts[0]' "$OUTPUT_FILE")" = literal.example.test ]
  [[ "$stderr" != *"hosts preserved"* ]]
  yq '.tempo.values.routes.inbound.tempo-query.hosts = ["canonical.example.test"]' \
    "$FIXTURES/package-domain/input.yaml" >"$INPUT_FILE"
  run --separate-stderr "$SCRIPT_PATH" --target 4 -o "$OUTPUT_FILE" "$INPUT_FILE"
  [ "$status" -eq 0 ]
  [ "$(yq '.packages.tempo.values.bb-common.routes.inbound.tempo-query.hosts[0]' "$OUTPUT_FILE")" = canonical.example.test ]
  [[ "$stderr" != *"hosts preserved"* ]]
}

@test "preserves legacy host templates when package global domain is overridden" {
  yq 'del(.tempo.values.domain) | .tempo.values.global.domain = "different.example.test"' \
    "$FIXTURES/package-domain/input.yaml" >"$INPUT_FILE"
  run --separate-stderr "$SCRIPT_PATH" --target 4 -o "$OUTPUT_FILE" "$INPUT_FILE"
  [ "$status" -eq 0 ]
  [ "$(yq '.packages.tempo.values.bb-common.istio.tempoQuery.hosts[0]' "$OUTPUT_FILE")" = 'tempo.{{ .Values.domain }}' ]
  [ "$(yq '.packages.tempo.values.bb-common | has("routes")' "$OUTPUT_FILE")" = false ]
  [[ "$stderr" == *"values.global.domain overrides a template context"* ]]
}

@test "empty and absent legacy hosts do not create inbound routes" {
  assert_fixture empty-hosts
  [ "$(yq '[.packages[].values.bb-common.routes.inbound | select(. != null)] | length' "$OUTPUT_FILE")" -eq 0 ]
}

@test "preserves and diagnoses ambiguous custom removed and unknown endpoints" {
  assert_fixture manual-review
  [[ "$stderr" == *"Review: the following legacy Istio hosts require manual migration"* ]]
  for path in \
    packages.monitoring.istio.hosts \
    packages.tempo.values.bb-common.istio.unknownEndpoint.hosts \
    packages.custom-app.istio.hosts \
    packages.custom-app.values.istio.app.hosts \
    packages.custom-app.values.bb-common.istio.hosts \
    packages.minioOperator.values.bb-common.istio.console.hosts; do
    [[ "$stderr" == *"$path: no unambiguous built-in endpoint mapping; hosts preserved"* ]]
  done
  [[ "$stderr" == *"routes.inbound.<route>.hosts explicitly"* ]]
  [[ "$stderr" != *"ambiguous.example.test"* ]]
  [[ "$stderr" != *"custom-values.example.test"* ]]
}

@test "target 3 retains historical chart hosts and staged migration matches target 4" {
  run "$SCRIPT_PATH" --target 3 -o "$OUTPUT_FILE" "$FIXTURES/tempo-release/input.yaml"
  [ "$status" -eq 0 ]
  assert_yaml_equal "$FIXTURES/tempo-release/expected-target-3.yaml" "$OUTPUT_FILE"

  run "$SCRIPT_PATH" --target 4 -o "${OUTPUT_FILE}.four" "$OUTPUT_FILE"
  [ "$status" -eq 0 ]
  assert_yaml_equal "$FIXTURES/tempo-release/expected.yaml" "${OUTPUT_FILE}.four"
}

@test "target 3 retains package-level hosts and secondary source migration is idempotent" {
  run "$SCRIPT_PATH" --target 3 -o "$OUTPUT_FILE" "$FIXTURES/package-level/input.yaml"
  [ "$status" -eq 0 ]
  [ "$(yq '.packages.tempo.istio.hosts[0]' "$OUTPUT_FILE")" = tempo.example.test ]
  [ "$(yq '.packages.argocd.istio.hosts[0]' "$OUTPUT_FILE")" = argocd.example.test ]
  [ "$(yq '.packages.kiali.istio.hosts[1]' "$OUTPUT_FILE")" = '${KIALI_HOST}' ]

  run /bin/bash "$SCRIPT_PATH" --target 4 --omit-package-configuration \
    -o "${OUTPUT_FILE}.four" "$OUTPUT_FILE"
  [ "$status" -eq 0 ]
  [ "$(yq 'has("packageConfiguration")' "${OUTPUT_FILE}.four")" = false ]
  [ "$(yq '.packages.tempo.values.bb-common.routes.inbound.tempo-query.hosts[0]' "${OUTPUT_FILE}.four")" = tempo.example.test ]
  run /bin/bash "$SCRIPT_PATH" --target 4 --omit-package-configuration \
    -o "${OUTPUT_FILE}.second" "${OUTPUT_FILE}.four"
  [ "$status" -eq 0 ]
  cmp "${OUTPUT_FILE}.four" "${OUTPUT_FILE}.second"
}

@test "later raw inputs replace host lists before conversion" {
  yq '.tempo.values.istio.tempoQuery.hosts = ["overlay.example.test"]' \
    "$FIXTURES/tempo-release/input.yaml" >"$INPUT_FILE"
  run "$SCRIPT_PATH" --target 4 -o "$OUTPUT_FILE" \
    "$FIXTURES/tempo-release/input.yaml" "$INPUT_FILE"
  [ "$status" -eq 0 ]
  [ "$(yq -o=json -I=0 '.packages.tempo.values.bb-common.routes.inbound.tempo-query.hosts' "$OUTPUT_FILE")" = '["overlay.example.test"]' ]
}

@test "canonical package hostname overrides win over root aliases" {
  yq -n '.packageConfiguration.version = "v1" |
    .tempo.values.istio.tempoQuery.hosts = ["root.example.test"] |
    .packages.tempo.values.istio.tempoQuery.hosts = ["canonical.example.test"]' >"$INPUT_FILE"
  run "$SCRIPT_PATH" --target 4 -o "$OUTPUT_FILE" "$INPUT_FILE"
  [ "$status" -eq 0 ]
  [ "$(yq -o=json -I=0 '.packages.tempo.values.bb-common.routes.inbound.tempo-query.hosts' "$OUTPUT_FILE")" = '["canonical.example.test"]' ]
}

@test "flat routes retain precedence over legacy endpoint hosts" {
  yq '.tempo.values.routes.inbound.tempo-query.hosts = ["route.example.test"]' \
    "$FIXTURES/tempo-release/input.yaml" >"$INPUT_FILE"
  run "$SCRIPT_PATH" --target 4 -o "$OUTPUT_FILE" "$INPUT_FILE"
  [ "$status" -eq 0 ]
  [ "$(yq '.packages.tempo.values.bb-common.routes.inbound.tempo-query.hosts[0]' "$OUTPUT_FILE")" = route.example.test ]
  [ "$(yq '.packages.tempo.values.bb-common | has("istio")' "$OUTPUT_FILE")" = false ]
}

@test "parent HelmRelease conversion preserves the complete envelope" {
  FIXTURE="$FIXTURES/package-level/input.yaml" yq -n '
    .apiVersion = "helm.toolkit.fluxcd.io/v2" | .kind = "HelmRelease" |
    .metadata = {"name": "bigbang", "namespace": "bigbang"} |
    .spec.valuesFrom = [{"kind": "Secret", "name": "environment"}] |
    .spec.postRenderers = [{"kustomize": {"patches": []}}] |
    .spec.values = load(strenv(FIXTURE))' >"$INPUT_FILE"
  run "$SCRIPT_PATH" --target 4 --bigbang-helmrelease -o "$OUTPUT_FILE" "$INPUT_FILE"
  [ "$status" -eq 0 ]
  yq '.spec.values' "$OUTPUT_FILE" >"${OUTPUT_FILE}.values"
  assert_yaml_equal "$FIXTURES/package-level/expected.yaml" "${OUTPUT_FILE}.values"
  diff -u <(yq -o=json 'del(.spec.values)' "$INPUT_FILE" | jq -S '.') \
    <(yq -o=json 'del(.spec.values)' "$OUTPUT_FILE" | jq -S '.')
}

@test "package HelmRelease patches convert hosts after later patch overrides" {
  FIXTURE="$FIXTURES/tempo-release/input.yaml" yq -n '
    .apiVersion = "helm.toolkit.fluxcd.io/v2" | .kind = "HelmRelease" |
    .metadata.name = "tempo" | .spec.timeout = "20m" |
    .spec.values = load(strenv(FIXTURE)).tempo.values' >"$INPUT_FILE"
  yq '.spec.values.istio.tempoQuery.hosts = ["patch.example.test"]' \
    "$INPUT_FILE" >"${INPUT_FILE}.later"
  run "$SCRIPT_PATH" --target 4 -o "$OUTPUT_FILE" "$FIXTURES/tempo-release/input.yaml" \
    --helmrelease-patch "$INPUT_FILE" --helmrelease-patch "${INPUT_FILE}.later"
  [ "$status" -eq 0 ]
  [ "$(yq '.packages.tempo.values.bb-common.routes.inbound.tempo-query.hosts[0]' "$OUTPUT_FILE")" = patch.example.test ]
  [ "$(yq '.packages.tempo.flux.timeout' "$OUTPUT_FILE")" = 20m ]
}

@test "decrypted Secret stringData and data inputs share hostname conversion" {
  for field in stringData data; do
    if [[ "$field" == data ]]; then
      base64 <"$FIXTURES/tempo-release/input.yaml" | tr -d '\n' >"${INPUT_FILE}.payload"
    else
      cp "$FIXTURES/tempo-release/input.yaml" "${INPUT_FILE}.payload"
    fi
    FIELD="$field" PAYLOAD="${INPUT_FILE}.payload" yq -n '
      .apiVersion = "v1" | .kind = "Secret" |
      .metadata.name = "environment" |
      .[strenv(FIELD)] = {"unrelated": "preserve-me"} |
      .[strenv(FIELD)]."values.yaml" = load_str(strenv(PAYLOAD))' >"$INPUT_FILE"
    run "$SCRIPT_PATH" --target 4 --secret-key values.yaml -o "$OUTPUT_FILE" "$INPUT_FILE"
    [ "$status" -eq 0 ]
    if [[ "$field" == data ]]; then
      yq -r '.data."values.yaml"' "$OUTPUT_FILE" | base64 --decode >"${OUTPUT_FILE}.values"
    else
      yq -r '.stringData."values.yaml"' "$OUTPUT_FILE" >"${OUTPUT_FILE}.values"
    fi
    assert_yaml_equal "$FIXTURES/tempo-release/expected.yaml" "${OUTPUT_FILE}.values"
    diff -u <(FIELD="$field" yq -o=json 'del(.[strenv(FIELD)]."values.yaml")' "$INPUT_FILE" | jq -S '.') \
      <(FIELD="$field" yq -o=json 'del(.[strenv(FIELD)]."values.yaml")' "$OUTPUT_FILE" | jq -S '.')
  done
}

@test "invalid hostname types fail without replacing output or leaking host values" {
  printf 'existing output\n' >"$OUTPUT_FILE"
  for hosts in '"private-test-sentinel"' '{"private-test-sentinel": true}' '[12]' '[null]' '[""]'; do
    HOSTS="$hosts" yq '.tempo.values.istio.tempoQuery.hosts = env(HOSTS)' \
      "$FIXTURES/tempo-release/input.yaml" >"$INPUT_FILE"
    run --separate-stderr "$SCRIPT_PATH" --target 4 -o "$OUTPUT_FILE" "$INPUT_FILE"
    [ "$status" -ne 0 ]
    [ -z "$output" ]
    [[ "$stderr" == *"must be a list of non-empty strings or null"* ]]
    [[ "$stderr" != *"private-test-sentinel"* ]]
    [ "$(<"$OUTPUT_FILE")" = 'existing output' ]
  done
}

@test "incompatible destination maps fail without writing partial output" {
  for expression in \
    '.packages.tempo.values = null' \
    '.packages.tempo.values.bb-common = []' \
    '.packages.tempo.values.bb-common.routes = false' \
    '.packages.tempo.values.bb-common.routes.inbound = "invalid"' \
    '.packages.tempo.values.bb-common.routes.inbound.tempo-query = null'; do
    EXPRESSION="$expression" yq -n '
      .packageConfiguration.version = "v1" |
      .packages.tempo.istio.hosts = ["private-test-sentinel"] |
      eval(strenv(EXPRESSION))' >"$INPUT_FILE"
    run --separate-stderr "$SCRIPT_PATH" --target 4 -o "$OUTPUT_FILE" "$INPUT_FILE"
    [ "$status" -ne 0 ]
    [ -z "$output" ]
    [[ "$stderr" == *"destination ancestors must be mappings"* ]]
    [[ "$stderr" != *"private-test-sentinel"* ]]
    [ ! -e "$OUTPUT_FILE" ]
  done
}

@test "migrated host overrides reach emitted Tempo Monitoring and GitLab values" {
  run "$SCRIPT_PATH" --target 4 -o "$OUTPUT_FILE" "$FIXTURES/endpoint-mappings/input.yaml"
  [ "$status" -eq 0 ]
  run helm template bigbang "$REPO_ROOT/chart" -f "$OUTPUT_FILE" \
    --set packages.tempo.enabled=true --set packages.monitoring.enabled=true \
    --set packages.gitlab.enabled=true
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" >"${OUTPUT_FILE}.rendered"
  for package in tempo monitoring gitlab; do
    PACKAGE="$package" yq -r 'select(.kind == "Secret" and .metadata.name == ("bigbang-" + strenv(PACKAGE) + "-values")) |
      .stringData.overlays' "${OUTPUT_FILE}.rendered" >"${OUTPUT_FILE}.overlays"
    [ -s "${OUTPUT_FILE}.overlays" ]
    diff -u <(PACKAGE="$package" yq -o=json '.packages[strenv(PACKAGE)].values.bb-common.routes.inbound' "$OUTPUT_FILE" | jq -S '.') \
      <(yq -o=json '.bb-common.routes.inbound' "${OUTPUT_FILE}.overlays" | jq -S '.')
    [ "$(yq '.bb-common | has("istio")' "${OUTPUT_FILE}.overlays")" = "$(PACKAGE="$package" yq '.packages[strenv(PACKAGE)].values.bb-common | has("istio")' "$OUTPUT_FILE")" ]

    PACKAGE="$package" yq 'select(.kind == "Secret" and .metadata.name == ("bigbang-" + strenv(PACKAGE) + "-values")) |
      (.stringData.common | from_yaml) * (.stringData.defaults | from_yaml) * (.stringData.overlays | from_yaml)' \
      "${OUTPUT_FILE}.rendered" >"${OUTPUT_FILE}.effective"
    for route in $(yq -r '.bb-common.routes.inbound | keys | .[]' "${OUTPUT_FILE}.overlays"); do
      diff -u <(ROUTE="$route" yq -o=json '.bb-common.routes.inbound[strenv(ROUTE)].hosts' "${OUTPUT_FILE}.overlays" | jq -S '.') \
        <(ROUTE="$route" yq -o=json '.bb-common.routes.inbound[strenv(ROUTE)].hosts' "${OUTPUT_FILE}.effective" | jq -S '.')
    done
    [ "$(PACKAGE="$package" yq -o=json -I=0 'select(.kind == "HelmRelease" and .metadata.name == strenv(PACKAGE)) |
      .spec.valuesFrom' "${OUTPUT_FILE}.rendered" | jq -c 'map(.valuesKey)')" = '["common","defaults","overlays"]' ]
  done
}

@test "migrated Tempo hostname renders in the actual pinned package VirtualService" {
  [ -n "${TEMPO_CHART_PATH:-}" ] || skip "Set TEMPO_CHART_PATH to the pinned Tempo 3.2.1-bb.1 chart with dependencies"
  [ "$(yq '.version' "$TEMPO_CHART_PATH/Chart.yaml")" = 3.2.1-bb.1 ]
  [ -f "$TEMPO_CHART_PATH/charts/bb-common-1.6.1.tgz" ]

  run "$SCRIPT_PATH" --target 4 -o "$OUTPUT_FILE" "$FIXTURES/tempo-release/input.yaml"
  [ "$status" -eq 0 ]
  run helm template bigbang "$REPO_ROOT/chart" -f "$OUTPUT_FILE" \
    --set domain=release.example.test --set packages.tempo.enabled=true
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" >"${OUTPUT_FILE}.rendered"
  yq 'select(.kind == "Secret" and .metadata.name == "bigbang-tempo-values") |
    (.stringData.common | from_yaml) * (.stringData.defaults | from_yaml) * (.stringData.overlays | from_yaml) |
    .bb-common.routes.inbound.tempo-query.enabled = true' \
    "${OUTPUT_FILE}.rendered" >"${OUTPUT_FILE}.package-values"

  run helm template tempo "$TEMPO_CHART_PATH" --api-versions networking.istio.io/v1 \
    -f "${OUTPUT_FILE}.package-values"
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" >"${OUTPUT_FILE}.package-rendered"
  [ "$(yq -o=json -I=0 'select(.kind == "VirtualService" and .metadata.name == "tempo-query") |
    .spec.hosts' "${OUTPUT_FILE}.package-rendered")" = '["tempo.release.example.test"]' ]
}

@test "package-specific domain is preserved for manual migration and the correct Tempo route renders" {
  [ -n "${TEMPO_CHART_PATH:-}" ] || skip "Set TEMPO_CHART_PATH to the pinned Tempo 3.2.1-bb.1 chart with dependencies"
  [ "$(yq '.version' "$TEMPO_CHART_PATH/Chart.yaml")" = 3.2.1-bb.1 ]
  [ -f "$TEMPO_CHART_PATH/charts/bb-common-1.6.1.tgz" ]

  run --separate-stderr "$SCRIPT_PATH" --target 4 -o "$OUTPUT_FILE" "$FIXTURES/package-domain/input.yaml"
  [ "$status" -eq 0 ]
  [[ "$stderr" == *"packages.tempo.values.domain"*"hosts preserved"* ]]
  [ "$(yq '.packages.tempo.values.bb-common | has("routes")' "$OUTPUT_FILE")" = false ]
  # Apply the diagnostic's manual migration using the package-specific domain.
  yq -i '.packages.tempo.values.bb-common.routes.inbound.tempo-query.hosts = ["tempo.traces.example.test"] |
    del(.packages.tempo.values.bb-common.istio.tempoQuery)' "$OUTPUT_FILE"
  run helm template bigbang "$REPO_ROOT/chart" -f "$OUTPUT_FILE" --set packages.tempo.enabled=true
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" >"${OUTPUT_FILE}.rendered"
  yq 'select(.kind == "Secret" and .metadata.name == "bigbang-tempo-values") |
    (.stringData.common | from_yaml) * (.stringData.defaults | from_yaml) * (.stringData.overlays | from_yaml) |
    .bb-common.routes.inbound.tempo-query.enabled = true' \
    "${OUTPUT_FILE}.rendered" >"${OUTPUT_FILE}.package-values"
  run helm template tempo "$TEMPO_CHART_PATH" --api-versions networking.istio.io/v1 \
    -f "${OUTPUT_FILE}.package-values"
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" >"${OUTPUT_FILE}.package-rendered"
  [ "$(yq -o=json -I=0 'select(.kind == "VirtualService" and .metadata.name == "tempo-query") |
    .spec.hosts' "${OUTPUT_FILE}.package-rendered")" = '["tempo.traces.example.test"]' ]
}

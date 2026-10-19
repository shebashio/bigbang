#!/usr/bin/env bats

setup() {
  REPO_ROOT=$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)
  export HELM_DOCS_BIN=${HELM_DOCS_BIN:-helm-docs}
  command -v "$HELM_DOCS_BIN" >/dev/null 2>&1 || skip "helm-docs v1.14.2 is required"
  FIXTURE_ROOT="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${FIXTURE_ROOT}/chart" "${FIXTURE_ROOT}/scripts" \
    "${FIXTURE_ROOT}/docs/configuration"
  cp "${REPO_ROOT}/chart/Chart.yaml" "${REPO_ROOT}/chart/values.yaml" \
    "${FIXTURE_ROOT}/chart/"
  cp "${REPO_ROOT}/docs/configuration/base-config.md.gotmpl" \
    "${FIXTURE_ROOT}/docs/configuration/"
  cp "${REPO_ROOT}/scripts/generate-values-reference.sh" "${FIXTURE_ROOT}/scripts/"
  GENERATOR="${FIXTURE_ROOT}/scripts/generate-values-reference.sh"
  REFERENCE="${FIXTURE_ROOT}/docs/configuration/base-config.md"
}

@test "values reference expands shared fields without exposing YAML merge keys" {
  run "$GENERATOR" --write
  [ "$status" -eq 0 ]
  [[ "$output" != *"level=error"* ]]
  ! rg -q 'packages\.[^ |]*\.<<' "$REFERENCE"
  rg -q 'Shared Package Fields' "$REFERENCE"
  rg -q '^\| packages.istioCNI.enabled \| bool \| `false`' "$REFERENCE"
  rg -q '^\| packages.istioCNI \|.*"sourceType":"git"' "$REFERENCE"
  rg -q 'custom-package-values.yaml' "$REFERENCE"
  # Generation must never expand or rewrite the maintained values file itself.
  cmp "${REPO_ROOT}/chart/values.yaml" "${FIXTURE_ROOT}/chart/values.yaml"
}

@test "values reference check detects drift without rewriting the reference" {
  "$GENERATOR" --write
  run "$GENERATOR" --check
  [ "$status" -eq 0 ]
  printf '\nmanual drift\n' >>"$REFERENCE"
  cp "$REFERENCE" "${BATS_TEST_TMPDIR}/before.md"

  run "$GENERATOR" --check

  [ "$status" -ne 0 ]
  [[ "$output" == *"generated values reference is stale"* ]]
  cmp "${BATS_TEST_TMPDIR}/before.md" "$REFERENCE"
}

#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CHART_PATH="${REPO_ROOT}/chart"
REFERENCE_PATH="${REPO_ROOT}/docs/configuration/base-config.md"
TEMPLATE_PATH="${REPO_ROOT}/docs/configuration/base-config.md.gotmpl"
MODE=${1:---write}
HELM_DOCS_BIN=${HELM_DOCS_BIN:-helm-docs}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

if [[ $# -gt 1 || "$MODE" != "--write" && "$MODE" != "--check" ]]; then
  fail "usage: $(basename "$0") [--write|--check]"
fi

command -v "$HELM_DOCS_BIN" >/dev/null 2>&1 \
  || fail "helm-docs v1.14.2 is required; install it or set HELM_DOCS_BIN"
command -v yq >/dev/null 2>&1 || fail "Mike Farah yq v4.47.1 or newer is required"
yq --yaml-fix-merge-anchor-to-spec=true --null-input '.' >/dev/null 2>&1 \
  || fail "Mike Farah yq v4.47.1 or newer with --yaml-fix-merge-anchor-to-spec support is required"

generate() {
  local chart_root=$1
  "$HELM_DOCS_BIN" \
    --chart-search-root "$chart_root" \
    --template-files ../docs/configuration/base-config.md.gotmpl \
    --output-file ../docs/configuration/base-config.md \
    --sort-values-order file \
    --skip-version-footer \
    --log-level warning
}

TASK_TMP=$(mktemp -d "${TMPDIR:-/tmp}/bigbang-values-reference.XXXXXX")
cleanup() {
  rm -f "${TASK_TMP}/chart/Chart.yaml" "${TASK_TMP}/chart/values.yaml" \
    "${TASK_TMP}/docs/configuration/base-config.md" \
    "${TASK_TMP}/docs/configuration/base-config.md.gotmpl"
  rmdir "${TASK_TMP}/chart" "${TASK_TMP}/docs/configuration" \
    "${TASK_TMP}/docs" "$TASK_TMP"
}
trap cleanup EXIT

mkdir -p "${TASK_TMP}/chart" "${TASK_TMP}/docs/configuration"
cp "${CHART_PATH}/Chart.yaml" "${TASK_TMP}/chart/"
# helm-docs walks YAML nodes rather than Helm's resolved values. Expand anchors
# in a temporary input so the reference contains actual values paths, not `<<`.
yq --yaml-fix-merge-anchor-to-spec=true 'explode(.)' "${CHART_PATH}/values.yaml" \
  >"${TASK_TMP}/chart/values.yaml"
cp "$TEMPLATE_PATH" "${TASK_TMP}/docs/configuration/"
generate "${TASK_TMP}/chart"

if [[ "$MODE" == "--check" ]]; then
  cmp -s "$REFERENCE_PATH" "${TASK_TMP}/docs/configuration/base-config.md" \
    || fail "generated values reference is stale; run scripts/generate-values-reference.sh --write"

  printf '%s\n' 'Generated values reference is up to date.'
else
  cp "${TASK_TMP}/docs/configuration/base-config.md" "$REFERENCE_PATH"
  printf '%s\n' 'Updated docs/configuration/base-config.md.'
fi

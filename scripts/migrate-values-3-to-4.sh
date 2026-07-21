#!/usr/bin/env bash

# Migrate Big Bang 3.x package values to the unified Big Bang 4.x package map.
# Requires Mike Farah yq v4: https://github.com/mikefarah/yq

set -euo pipefail

ROOT_PACKAGES=(
  istioCNI istioCRDs gatewayAPI istiod istioGateway ztunnel
  kiali gatekeeper kyverno kyvernoPolicies kyvernoReporter
  elasticsearchKibana eckOperator fluentbit alloy loki neuvector tempo
  prometheusOperatorCRDs monitoring grafana twistlock bbctl renovate
)

ADDON_PACKAGES=(
  argocd authservice minioOperator minio gitlab gitlabRunner sonarqube
  fortify anchoreEnterprise mattermostOperator mattermost velero keycloak
  vault metricsServer harbor headlamp thanos externalSecrets mimir
)

usage() {
  cat <<'EOF'
Usage: migrate-values-3-to-4.sh [OPTIONS] INPUT

Move Big Bang 3.x built-in package configuration from top-level and
addons.<name> paths to the Big Bang 4.x packages.<name> paths.

By default, migrated YAML is written to standard output and INPUT is unchanged.

Options:
  -o, --output FILE  Write migrated values to FILE.
  -i, --in-place     Replace INPUT after creating INPUT.bak.
  -h, --help         Show this help.

If both a legacy path and packages.<name> exist, they are recursively merged
and packages.<name> takes precedence. Unrecognized package entries are left
unchanged. The migration is idempotent.

Examples:
  scripts/migrate-values-3-to-4.sh values.yaml > values-4.x.yaml
  scripts/migrate-values-3-to-4.sh -o values-4.x.yaml values.yaml
  scripts/migrate-values-3-to-4.sh --in-place values.yaml
EOF
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

OUTPUT_FILE=""
IN_PLACE=false
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
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      fail "unknown option: $1"
      ;;
    *)
      [[ -z "$INPUT_FILE" ]] || fail "only one input file may be provided"
      INPUT_FILE=$1
      shift
      ;;
  esac
done

[[ -n "$INPUT_FILE" ]] || fail "an input values file is required"
[[ -f "$INPUT_FILE" ]] || fail "input file does not exist: $INPUT_FILE"
[[ -r "$INPUT_FILE" ]] || fail "input file is not readable: $INPUT_FILE"
command -v yq >/dev/null 2>&1 || fail "Mike Farah yq v4 is required"
[[ "$(yq --version 2>/dev/null)" =~ version\ v4\. ]] || fail "Mike Farah yq v4 is required"

if [[ "$IN_PLACE" == true && -n "$OUTPUT_FILE" ]]; then
  fail "--in-place and --output cannot be used together"
fi
if [[ -n "$OUTPUT_FILE" && "$OUTPUT_FILE" == "$INPUT_FILE" ]]; then
  fail "use --in-place to replace the input file"
fi

yq -e 'tag == "!!map"' "$INPUT_FILE" >/dev/null 2>&1 \
  || fail "the values document root must be a YAML mapping"
yq -e '(.packages == null) or (.packages | tag == "!!map")' "$INPUT_FILE" >/dev/null 2>&1 \
  || fail "packages must be a YAML mapping"
yq -e '(.addons == null) or (.addons | tag == "!!map")' "$INPUT_FILE" >/dev/null 2>&1 \
  || fail "addons must be a YAML mapping"

WORK_FILE=$(mktemp "${TMPDIR:-/tmp}/bigbang-values-migration.XXXXXX")
trap 'rm -f "$WORK_FILE"' EXIT
cp "$INPUT_FILE" "$WORK_FILE"

MIGRATED_PATHS=()

for package_name in "${ROOT_PACKAGES[@]}"; do
  if PACKAGE_NAME="$package_name" yq -e 'has(strenv(PACKAGE_NAME))' "$WORK_FILE" >/dev/null 2>&1; then
    PACKAGE_NAME="$package_name" yq -i '
      .packages = (.packages // {}) |
      .packages[strenv(PACKAGE_NAME)] =
        ((.[strenv(PACKAGE_NAME)] // {}) * (.packages[strenv(PACKAGE_NAME)] // {})) |
      del(.[strenv(PACKAGE_NAME)])
    ' "$WORK_FILE"
    MIGRATED_PATHS+=("$package_name -> packages.$package_name")
  fi
done

for package_name in "${ADDON_PACKAGES[@]}"; do
  if PACKAGE_NAME="$package_name" yq -e '.addons | has(strenv(PACKAGE_NAME))' "$WORK_FILE" >/dev/null 2>&1; then
    PACKAGE_NAME="$package_name" yq -i '
      .packages = (.packages // {}) |
      .packages[strenv(PACKAGE_NAME)] =
        ((.addons[strenv(PACKAGE_NAME)] // {}) * (.packages[strenv(PACKAGE_NAME)] // {})) |
      del(.addons[strenv(PACKAGE_NAME)])
    ' "$WORK_FILE"
    MIGRATED_PATHS+=("addons.$package_name -> packages.$package_name")
  fi
done

if yq -e '(.addons | tag == "!!map") and (.addons | length == 0)' "$WORK_FILE" >/dev/null 2>&1; then
  yq -i 'del(.addons)' "$WORK_FILE"
fi

if [[ "$IN_PLACE" == true ]]; then
  BACKUP_FILE="${INPUT_FILE}.bak"
  [[ ! -e "$BACKUP_FILE" ]] || fail "backup already exists: $BACKUP_FILE"
  cp -p "$INPUT_FILE" "$BACKUP_FILE"
  cp "$WORK_FILE" "$INPUT_FILE"
  printf 'Migrated %s; backup written to %s\n' "$INPUT_FILE" "$BACKUP_FILE" >&2
elif [[ -n "$OUTPUT_FILE" ]]; then
  cp "$WORK_FILE" "$OUTPUT_FILE"
  printf 'Migrated values written to %s\n' "$OUTPUT_FILE" >&2
else
  cat "$WORK_FILE"
fi

if [[ ${#MIGRATED_PATHS[@]} -eq 0 ]]; then
  printf 'No legacy built-in package paths found.\n' >&2
else
  printf 'Migrated package paths:\n' >&2
  printf '  %s\n' "${MIGRATED_PATHS[@]}" >&2
fi

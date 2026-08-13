#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT=$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)
  GENERATOR="${REPO_ROOT}/scripts/generate-package-schemas.sh"
}

@test "generated canonical package schemas are current" {
  run "$GENERATOR" --check

  [ "$status" -eq 0 ]
  [ "$output" = "Generated package metadata files are up to date." ]
}

@test "every catalog package has a generated canonical schema" {
  expected=$(yq -o=json '.packages | keys' "${REPO_ROOT}/chart/package-metadata.yaml" | jq -c 'sort')
  actual=$(jq -c '.["$defs"].canonicalPackages.properties | keys | sort' "${REPO_ROOT}/chart/values.schema.json")

  [ "$actual" = "$expected" ]
}

#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT=$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)
  GENERATOR="${REPO_ROOT}/scripts/generate-package-schemas.rb"
}

@test "generated canonical package schemas are current" {
  run "$GENERATOR" --check

  [ "$status" -eq 0 ]
  [ "$output" = "Generated package metadata files are up to date." ]
}

@test "every catalog package has a generated canonical schema" {
  run ruby -rjson -ryaml -e '
    root = ARGV.fetch(0)
    metadata = YAML.safe_load(File.read(File.join(root, "chart/package-metadata.yaml")))
    schema = JSON.parse(File.read(File.join(root, "chart/values.schema.json")))
    expected = metadata.fetch("packages").keys.sort
    actual = schema.dig("properties", "packages", "properties").keys.sort
    abort "catalog and schema package names differ" unless actual == expected
  ' "$REPO_ROOT"

  [ "$status" -eq 0 ]
}

#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT=$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)
  GENERATOR="${REPO_ROOT}/scripts/generate-package-schemas.sh"
}

create_generator_fixture() {
  FIXTURE_ROOT="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${FIXTURE_ROOT}/chart/templates" "${FIXTURE_ROOT}/scripts"
  cp "${REPO_ROOT}/chart/package-metadata.yaml" \
    "${REPO_ROOT}/chart/values.schema.json" \
    "${REPO_ROOT}/chart/values.yaml" \
    "${FIXTURE_ROOT}/chart/"
  cp "${REPO_ROOT}/scripts/generate-package-schemas.jq" \
    "${REPO_ROOT}/scripts/generate-package-schemas.sh" \
    "${REPO_ROOT}/scripts/migrate-values-3-to-4.sh" \
    "${FIXTURE_ROOT}/scripts/"
  while IFS= read -r template_directory; do
    mkdir -p "${FIXTURE_ROOT}/chart/templates/${template_directory}"
  done < <(yq -r '.packages[].templateDirectory' "${FIXTURE_ROOT}/chart/package-metadata.yaml")
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

@test "schema generation resolves shared defaults with explicit package precedence" {
  create_generator_fixture
  # A new shared field must be discovered for both the anchor owner and aliases,
  # while a package's explicit map replaces the shared map before Helm merging.
  yq --yaml-fix-merge-anchor-to-spec=true -i \
    '.packages.istioCNI."<<".sharedExample = {"common": true} |
     .packages.kiali.sharedExample = {"specific": true}' \
    "${FIXTURE_ROOT}/chart/values.yaml"

  run "${FIXTURE_ROOT}/scripts/generate-package-schemas.sh" --write

  [ "$status" -eq 0 ]
  jq -e '."$defs".packagePartials.overrides |
    .istioCNI.properties.sharedExample == true and
    .gatewayAPI.properties.sharedExample == true and
    .kiali.properties.sharedExample == true' \
    "${FIXTURE_ROOT}/chart/values.schema.json" >/dev/null
}

@test "built-in schema definitions match the catalog and legacy paths are absent" {
  expected=$(yq -o=json '.packages | keys' "${REPO_ROOT}/chart/package-metadata.yaml" | jq -c 'sort')
  actual=$(jq -c '."$defs".builtinPackageSchemas.properties | keys | sort' "${REPO_ROOT}/chart/values.schema.json")
  [ "$actual" = "$expected" ]

  jq -e --argjson names "$expected" '
    . as $schema |
    (.properties.packages."$ref" == "#/$defs/canonicalPackages") and
    (.allOf == null) and
    (.properties | has("addons") | not) and
    all($names[]; . as $name | ($schema.properties | has($name) | not))
  ' "${REPO_ROOT}/chart/values.schema.json" >/dev/null
}

@test "package metadata groups categories and alphabetizes canonical keys" {
  category_order=$(yq -r '.packages[].category' \
    "${REPO_ROOT}/chart/package-metadata.yaml" | awk '!seen[$0]++')
  [ "$category_order" = $'core\naddon' ]

  for category in core addon; do
    actual=$(CATEGORY="$category" yq -r \
      '.packages | to_entries[] | select(.value.category == strenv(CATEGORY)) | .key' \
      "${REPO_ROOT}/chart/package-metadata.yaml")
    expected=$(printf '%s\n' "$actual" | LC_ALL=C sort -f)

    [ "$actual" = "$expected" ]
  done
}

@test "rejects an integrated package template directory omitted from the catalog" {
  create_generator_fixture
  mkdir -p "${FIXTURE_ROOT}/chart/templates/example-package"
  touch "${FIXTURE_ROOT}/chart/templates/example-package/helmrelease.yaml"

  run "${FIXTURE_ROOT}/scripts/generate-package-schemas.sh" --check

  [ "$status" -ne 0 ]
  [ "$output" = "Error: integrated package template directory chart/templates/example-package is missing from chart/package-metadata.yaml" ]
}

@test "rejects a package key that is not a camelCase identifier" {
  create_generator_fixture
  yq -i '.packages."invalid-package" = .packages.kiali | del(.packages.kiali)' \
    "${FIXTURE_ROOT}/chart/package-metadata.yaml"

  run "${FIXTURE_ROOT}/scripts/generate-package-schemas.sh" --check

  [ "$status" -ne 0 ]
  [[ "$output" == *"package metadata package keys must use camelCase identifiers"* ]]
}

@test "rejects a template directory that is not kebab-case" {
  create_generator_fixture
  yq -i '.packages.kiali.templateDirectory = "Invalid_Directory"' \
    "${FIXTURE_ROOT}/chart/package-metadata.yaml"

  run "${FIXTURE_ROOT}/scripts/generate-package-schemas.sh" --check

  [ "$status" -ne 0 ]
  [[ "$output" == *"package metadata templateDirectory values must use kebab-case directory names"* ]]
}

@test "rejects a missing built-in schema definition" {
  create_generator_fixture
  jq 'del(."$defs".builtinPackageSchemas.properties.kiali)' \
    "${FIXTURE_ROOT}/chart/values.schema.json" >"${BATS_TEST_TMPDIR}/schema.json"
  cp "${BATS_TEST_TMPDIR}/schema.json" "${FIXTURE_ROOT}/chart/values.schema.json"

  run "${FIXTURE_ROOT}/scripts/generate-package-schemas.sh" --check

  [ "$status" -ne 0 ]
  [[ "$output" == *"built-in package schemas must match the package catalog"* ]]
}

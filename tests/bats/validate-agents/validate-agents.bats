#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT=$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)
  VALIDATOR="${REPO_ROOT}/scripts/validate-agents.sh"
  FIXTURE_ROOT="${BATS_TEST_TMPDIR}/repo"

  mkdir -p "$FIXTURE_ROOT"
  git -C "$FIXTURE_ROOT" init -q
  touch "${FIXTURE_ROOT}/CONTRIBUTING.md"
  write_valid_agents
}

write_valid_agents() {
  cat >"${FIXTURE_ROOT}/AGENTS.md" <<'EOF'
# AGENTS.md
<!-- big-bang-agents-standard: 1 -->

## Repository Purpose

This fixture tests the standard.

## Sources of Truth

Use `config.yaml`.

## Repository Layout

The root contains the fixture.

## Working Rules

Keep the fixture minimal.

## Commands

Run `true`.

## Validation

Run the validator.

## Big Bang Integration

This is a Big Bang test fixture.

## Authoritative References

Read [Contributing](CONTRIBUTING.md "contribution guide").
EOF
}

@test "accepts a valid repository-specific AGENTS.md" {
  run "$VALIDATOR" "${FIXTURE_ROOT}/AGENTS.md"

  [ "$status" -eq 0 ]
  [ "$output" = "AGENTS.md validation passed: ${FIXTURE_ROOT}/AGENTS.md" ]
}

@test "rejects a missing required section" {
  awk '$0 != "## Working Rules"' "${FIXTURE_ROOT}/AGENTS.md" >"${FIXTURE_ROOT}/invalid.md"
  mv "${FIXTURE_ROOT}/invalid.md" "${FIXTURE_ROOT}/AGENTS.md"

  run "$VALIDATOR" "${FIXTURE_ROOT}/AGENTS.md"

  [ "$status" -ne 0 ]
  [[ "$output" == *"must contain exactly one '## Working Rules' heading"* ]]
}

@test "rejects required sections in the wrong order" {
  awk '
    $0 == "## Commands" { print "## Validation"; next }
    $0 == "## Validation" { print "## Commands"; next }
    { print }
  ' "${FIXTURE_ROOT}/AGENTS.md" >"${FIXTURE_ROOT}/invalid.md"
  mv "${FIXTURE_ROOT}/invalid.md" "${FIXTURE_ROOT}/AGENTS.md"

  run "$VALIDATOR" "${FIXTURE_ROOT}/AGENTS.md"

  [ "$status" -ne 0 ]
  [[ "$output" == *"out of order"* ]]
}

@test "rejects AGENTS.md ignored by Git" {
  printf 'AGENTS.md\n' >"${FIXTURE_ROOT}/.gitignore"

  run "$VALIDATOR" "${FIXTURE_ROOT}/AGENTS.md"

  [ "$status" -ne 0 ]
  [[ "$output" == *"is ignored by Git"* ]]
}

@test "rejects an AGENTS.md outside the repository root" {
  mkdir -p "${FIXTURE_ROOT}/docs"
  cp "${FIXTURE_ROOT}/AGENTS.md" "${FIXTURE_ROOT}/docs/AGENTS.md"

  run "$VALIDATOR" "${FIXTURE_ROOT}/docs/AGENTS.md"

  [ "$status" -ne 0 ]
  [[ "$output" == *"must be the repository-root AGENTS.md"* ]]
}

@test "rejects an AGENTS.md outside a Git repository" {
  mkdir -p "${BATS_TEST_TMPDIR}/not-a-repo"
  cp "${FIXTURE_ROOT}/AGENTS.md" "${BATS_TEST_TMPDIR}/not-a-repo/AGENTS.md"

  run "$VALIDATOR" "${BATS_TEST_TMPDIR}/not-a-repo/AGENTS.md"

  [ "$status" -ne 0 ]
  [[ "$output" == *"is not inside a Git repository"* ]]
}

@test "rejects unresolved template placeholders" {
  printf '\nUse CHANGEME before committing.\n' >>"${FIXTURE_ROOT}/AGENTS.md"

  run "$VALIDATOR" "${FIXTURE_ROOT}/AGENTS.md"

  [ "$status" -ne 0 ]
  [[ "$output" == *"unresolved template placeholder"* ]]
}

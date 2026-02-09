# helpers/mock_aws.bash — Configurable aws CLI mock for BATS tests
#
# Usage in .bats files:
#   load '../helpers/mock_aws'
#
#   setup() {
#     k3ddev_load
#     setup_aws_mock "${BATS_TEST_DIRNAME}/../fixtures/aws_auth"
#   }

setup_aws_mock() {
  local fixture_dir="${1:?fixture directory required}"
  export MOCK_AWS_FIXTURE_DIR="${fixture_dir}"
  export MOCK_AWS_CALL_LOG=$(mktemp)
  export PATH="${BATS_TEST_DIRNAME}/../helpers/bin:${PATH}"
}

teardown_aws_mock() {
  rm -f "${MOCK_AWS_CALL_LOG}"
}

# Assert that a specific AWS API call was made
assert_aws_called() {
  local pattern="$1"
  grep -q "${pattern}" "${MOCK_AWS_CALL_LOG}" || {
    echo "Expected AWS call matching '${pattern}' but it was not found."
    echo "Actual calls:"
    cat "${MOCK_AWS_CALL_LOG}"
    return 1
  }
}

# Assert that a specific AWS API call was NOT made
assert_aws_not_called() {
  local pattern="$1"
  ! grep -q "${pattern}" "${MOCK_AWS_CALL_LOG}" || {
    echo "Did not expect AWS call matching '${pattern}' but it was found."
    return 1
  }
}

# Get the number of AWS API calls made
aws_call_count() {
  wc -l < "${MOCK_AWS_CALL_LOG}" | tr -d ' '
}

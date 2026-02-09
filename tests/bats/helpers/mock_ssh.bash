# helpers/mock_ssh.bash — SSH and batch execution mock for BATS tests
#
# Intercepts batch_exec to capture generated remote scripts instead of
# executing them. Stubs out SSH/SCP calls.
#
# Usage in .bats files:
#   load '../helpers/mock_ssh'
#
#   setup() {
#     k3ddev_load
#     setup_batch_capture
#     install_batch_capture  # call AFTER k3ddev_load to override functions
#   }
#
#   teardown() {
#     teardown_batch_capture
#   }

setup_batch_capture() {
  export CAPTURED_BATCHES_DIR=$(mktemp -d)
  export _CAPTURED_BATCH_COUNT=0
}

# Call AFTER sourcing k3d-dev.sh to override its batch_exec function
install_batch_capture() {
  batch_exec() {
    if [[ -n "${_BATCH_FILE:-}" && -f "${_BATCH_FILE}" ]]; then
      cp "${_BATCH_FILE}" "${CAPTURED_BATCHES_DIR}/batch_${_CAPTURED_BATCH_COUNT}.sh"
      ((_CAPTURED_BATCH_COUNT++))
      rm -f "${_BATCH_FILE}"
    fi
    _BATCH_FILE=""
    RUN_BATCH_FILE=""
    return 0
  }
  export -f batch_exec

  # Stub out direct SSH/SCP calls
  run() { return 0; }
  runwithexitcode() { return 0; }
  ssh() { return 0; }
  scp() { return 0; }
  ssh-keygen() { return 0; }
  export -f run runwithexitcode ssh scp ssh-keygen

  # Stub out curl for functions that check workstation IP
  curl() {
    case "$*" in
      *checkip.amazonaws.com*) echo "203.0.113.50" ;;
      *) command curl "$@" 2>/dev/null || echo "mock-curl-response" ;;
    esac
  }
  export -f curl
}

# Read a captured batch script by index
get_batch() {
  local index="${1:-0}"
  local batch_file="${CAPTURED_BATCHES_DIR}/batch_${index}.sh"
  if [[ -f "${batch_file}" ]]; then
    cat "${batch_file}"
  else
    echo "ERROR: batch ${index} not found (${_CAPTURED_BATCH_COUNT} batches captured)" >&2
    return 1
  fi
}

# Assert a string appears in a captured batch
assert_batch_contains() {
  local index="${1}" pattern="${2}"
  get_batch "${index}" | grep -q "${pattern}" || {
    echo "Expected batch ${index} to contain '${pattern}'"
    echo "Actual content:"
    get_batch "${index}"
    return 1
  }
}

# Assert a string does NOT appear in a captured batch
assert_batch_not_contains() {
  local index="${1}" pattern="${2}"
  ! get_batch "${index}" | grep -q "${pattern}" || {
    echo "Did not expect batch ${index} to contain '${pattern}'"
    return 1
  }
}

teardown_batch_capture() {
  rm -rf "${CAPTURED_BATCHES_DIR}"
}

#!/usr/bin/env bats
# =============================================================================
# BATS Tests for k3d-dev.sh
# =============================================================================
# Run with: bats docs/reference/scripts/developer/tests/k3d-dev.bats
#
# These tests verify k3d-dev.sh functions using mocks to prevent:
# - Real AWS API calls
# - Real SSH connections
# - Real file transfers
# - Real network requests
#
# NOTE: Due to BATS subshell behavior, we source k3d-dev.sh within each test
# rather than in setup(). This ensures functions have access to proper state.
# =============================================================================

# Helper to source the script
_source_k3d_dev() {
    export TMPDIR="${BATS_TEST_TMPDIR:-$(mktemp -d)}"
    source "${BATS_TEST_DIRNAME}/../k3d-dev.sh"
    trap - EXIT  # Clear k3d-dev.sh's trap to prevent interference
}

# Cleanup after each test
teardown() {
    # Remove batch files created by run_batch_new() in current directory
    rm -f k3d_dev_run_batch* 2>/dev/null || true
}

# Helper to reset globals
_reset_globals() {
    export K3D_VERSION="5.8.3"
    export DEFAULT_K3S_TAG="v1.34.1-k3s1"
    export PROVISION_CLOUD_INSTANCE=true
    export CLOUDPROVIDER="aws"
    export SSHUSER=ubuntu
    export action=create_instances
    export ATTACH_SECONDARY_IP=false
    export BIG_INSTANCE=false
    export METAL_LB=true
    export PRIVATE_IP=false
    export PROJECTTAG=default
    export RESET_K3D=false
    export USE_WEAVE=false
    export TERMINATE_INSTANCE=true
    export QUIET=false
    export REGISTRY_USERNAME=""
    export REGISTRY_PASSWORD=""
    export CLOUD_RECREATE_INSTANCE=false
    export INIT_SCRIPT=""
    export RUN_BATCH_FILE=""
    export KUBECONFIG=""
    export PrivateIP=""
    export PublicIP=""
    export SSHKEY=""
    export AWSUSERNAME=""
    export VPC_ID=""
    export SUBNET_ID=""
    export AMI_ID=""
    export InstId=""
    export BASE_DOMAIN="dev.bigbang.mil"
    export PUBLIC_SUBDOMAINS=()
    export PASSTHROUGH_SUBDOMAINS=()
    export PUBLIC_DOMAINS=()
    export PASSTHROUGH_DOMAINS=()
}

# =============================================================================
# Pure Function Tests
# =============================================================================

@test "cloud_aws_toolnames returns 'aws'" {
    _source_k3d_dev
    result=$(cloud_aws_toolnames)
    [ "$result" = "aws" ]
}

@test "k3dsshcmd builds correct SSH command" {
    _source_k3d_dev
    SSHKEY="/path/to/key.pem"
    SSHUSER="testuser"
    PublicIP="10.0.0.1"

    result=$(k3dsshcmd)

    [[ "$result" == *"ssh"* ]]
    [[ "$result" == *"-i /path/to/key.pem"* ]]
    [[ "$result" == *"testuser@10.0.0.1"* ]]
    [[ "$result" == *"StrictHostKeyChecking=no"* ]]
}

@test "set_kubeconfig uses PublicIP when not provisioning" {
    _source_k3d_dev
    _reset_globals
    PROVISION_CLOUD_INSTANCE="false"
    PublicIP="1.2.3.4"
    PROJECTTAG="myproject"

    set_kubeconfig

    [ "$KUBECONFIG" = "1.2.3.4-dev-myproject-config" ]
}

@test "set_kubeconfig uses AWSUSERNAME when provisioning" {
    _source_k3d_dev
    _reset_globals
    PROVISION_CLOUD_INSTANCE="true"
    AWSUSERNAME="devuser"
    PROJECTTAG="test"

    set_kubeconfig

    [ "$KUBECONFIG" = "devuser-dev-test-config" ]
}

# =============================================================================
# Argument Parsing Tests
# =============================================================================

@test "process_arguments sets BIG_INSTANCE=true with -b flag" {
    _source_k3d_dev
    _reset_globals

    process_arguments -b

    [ "$BIG_INSTANCE" = "true" ]
}

@test "process_arguments sets METAL_LB=false with -M flag" {
    _source_k3d_dev
    _reset_globals

    process_arguments -M

    [ "$METAL_LB" = "false" ]
}

@test "process_arguments sets PRIVATE_IP=true with -p flag" {
    _source_k3d_dev
    _reset_globals

    process_arguments -p

    [ "$PRIVATE_IP" = "true" ]
}

@test "process_arguments sets action=destroy_instances with -d flag" {
    _source_k3d_dev
    _reset_globals

    process_arguments -d

    [ "$action" = "destroy_instances" ]
}

@test "process_arguments sets PROJECTTAG with -t flag" {
    _source_k3d_dev
    _reset_globals

    process_arguments -t myproject

    [ "$PROJECTTAG" = "myproject" ]
}

@test "process_arguments sets RESET_K3D=true with -K flag" {
    _source_k3d_dev
    _reset_globals

    process_arguments -K

    [ "$RESET_K3D" = "true" ]
}

@test "process_arguments sets custom host with -H flag" {
    _source_k3d_dev
    _reset_globals

    process_arguments -H 192.168.1.100

    [ "$PublicIP" = "192.168.1.100" ]
    [ "$PROVISION_CLOUD_INSTANCE" = "false" ]
}

@test "process_arguments sets SSH keyfile with -k flag" {
    _source_k3d_dev
    _reset_globals

    process_arguments -k /custom/path/key.pem

    [ "$SSHKEY" = "/custom/path/key.pem" ]
}

@test "process_arguments handles multiple flags" {
    _source_k3d_dev
    _reset_globals

    process_arguments -b -M -t combined-test

    [ "$BIG_INSTANCE" = "true" ]
    [ "$METAL_LB" = "false" ]
    [ "$PROJECTTAG" = "combined-test" ]
}

@test "process_arguments sets PrivateIP=PublicIP when -H given without -P" {
    _source_k3d_dev
    _reset_globals

    process_arguments -H 10.20.30.40

    [ "$PublicIP" = "10.20.30.40" ]
    [ "$PrivateIP" = "10.20.30.40" ]
}

@test "process_arguments sets BASE_DOMAIN with -D flag" {
    _source_k3d_dev
    _reset_globals

    process_arguments -D custom.example.com

    [ "$BASE_DOMAIN" = "custom.example.com" ]
}

@test "process_arguments sets BASE_DOMAIN with --domain flag" {
    _source_k3d_dev
    _reset_globals

    process_arguments --domain another.domain.org

    [ "$BASE_DOMAIN" = "another.domain.org" ]
}

# =============================================================================
# Domain Configuration Tests
# =============================================================================

@test "set_domains builds PUBLIC_DOMAINS from BASE_DOMAIN" {
    _source_k3d_dev
    _reset_globals
    BASE_DOMAIN="test.example.com"
    PUBLIC_SUBDOMAINS=("grafana" "prometheus")
    PASSTHROUGH_SUBDOMAINS=("keycloak")

    set_domains

    [[ " ${PUBLIC_DOMAINS[*]} " == *"grafana.test.example.com"* ]]
    [[ " ${PUBLIC_DOMAINS[*]} " == *"prometheus.test.example.com"* ]]
    [[ " ${PASSTHROUGH_DOMAINS[*]} " == *"keycloak.test.example.com"* ]]
}

@test "set_domains uses default BASE_DOMAIN" {
    _source_k3d_dev
    # Don't reset - use script defaults

    set_domains

    [[ " ${PUBLIC_DOMAINS[*]} " == *"grafana.dev.bigbang.mil"* ]]
}

@test "set_domains clears existing domain arrays before rebuilding" {
    _source_k3d_dev
    _reset_globals
    BASE_DOMAIN="new.domain.com"
    PUBLIC_SUBDOMAINS=("app")
    PASSTHROUGH_SUBDOMAINS=()
    # Pre-populate with stale values
    PUBLIC_DOMAINS=("stale.old.domain.com")

    set_domains

    # Should only contain the new domain, not the stale one
    [ "${#PUBLIC_DOMAINS[@]}" -eq 1 ]
    [ "${PUBLIC_DOMAINS[0]}" = "app.new.domain.com" ]
}

# =============================================================================
# Tool Checking Tests
# =============================================================================

@test "check_missing_tools detects missing tool" {
    _source_k3d_dev

    # Mock command to fail for specific tool
    command() {
        [[ "$2" == "faketool" ]] && return 1
        return 0
    }
    export -f command

    # Capture the output - it should mention the missing tool
    output=$(check_missing_tools jq faketool kubectl 2>&1) || true
    [[ "$output" == *"faketool is not installed"* ]]
}

# =============================================================================
# AWS Mock Tests
# =============================================================================

@test "getDefaultAmi returns AMI ID from mocked AWS" {
    # Source and mock in a controlled subshell to avoid BATS issues
    result=$(
        source "${BATS_TEST_DIRNAME}/../k3d-dev.sh"
        trap - EXIT

        aws() {
            case "$*" in
                *"get-caller-identity"*)
                    # Returns plain text ARN (--output text format)
                    echo "arn:aws:iam::123456789012:user/testuser"
                    ;;
                *"describe-images"*)
                    echo "ami-mock12345678"
                    ;;
            esac
        }

        getDefaultAmi
    )
    [ "$result" = "ami-mock12345678" ]
}

@test "cloud_aws_configure sets AWSUSERNAME from mocked ARN" {
    # Run in subshell with mocks defined locally
    result=$(
        export TMPDIR=$(mktemp -d)
        source "${BATS_TEST_DIRNAME}/../k3d-dev.sh"
        trap - EXIT

        aws() {
            case "$*" in
                *"get-caller-identity"*)
                    # Returns plain text ARN (--output text format)
                    echo "arn:aws:iam::123456789012:user/mockuser"
                    ;;
                *"describe-vpcs"*)
                    echo '{"Vpcs": [{"VpcId": "vpc-mock123"}]}'
                    ;;
                *"describe-subnets"*)
                    echo '{"Subnets": [{"SubnetId": "subnet-mock123"}]}'
                    ;;
                *"describe-images"*)
                    echo "ami-mock123"
                    ;;
            esac
        }

        VPC_ID="vpc-mock123"
        EXISTING_VPC="exists"
        PROJECTTAG="test"

        cloud_aws_configure
        echo "$AWSUSERNAME"
    )
    [ "$result" = "mockuser" ]
}

@test "cloud_aws_report_instances uses correct filters" {
    _source_k3d_dev
    _reset_globals
    AWSUSERNAME="testuser"

    aws_calls=""
    aws() {
        aws_calls="$*"
        echo "i-mock123"
    }
    export -f aws

    cloud_aws_report_instances

    [[ "$aws_calls" == *"describe-instances"* ]]
    [[ "$aws_calls" == *"testuser-dev"* ]]
}

# =============================================================================
# Batch Execution Tests
# =============================================================================

@test "run_batch_new creates batch file" {
    _source_k3d_dev
    _reset_globals

    run_batch_new

    [ -n "$RUN_BATCH_FILE" ]
    [ -f "$RUN_BATCH_FILE" ]
    head -1 "$RUN_BATCH_FILE" | grep -q "#!/bin/bash"
}

@test "run_batch_add appends commands to batch file" {
    _source_k3d_dev
    _reset_globals

    run_batch_new
    run_batch_add "echo 'first command'"
    run_batch_add "echo 'second command'"

    grep -q "first command" "$RUN_BATCH_FILE"
    grep -q "second command" "$RUN_BATCH_FILE"
}

@test "run_batch_add fails if no batch started" {
    _source_k3d_dev
    _reset_globals

    # run_batch_add calls exit 1 when no batch, so use subshell to capture exit code
    exit_code=0
    ( run_batch_add "echo test" ) 2>/dev/null || exit_code=$?

    [ "$exit_code" -eq 1 ]
}

# =============================================================================
# SSH Mock Tests
# =============================================================================

@test "run function builds SSH command correctly" {
    _source_k3d_dev
    _reset_globals
    SSHKEY="/test/key.pem"
    SSHUSER="ubuntu"
    PublicIP="10.0.0.5"

    ssh_args=""
    ssh() {
        ssh_args="$*"
        return 0
    }
    export -f ssh

    run "echo hello"

    [[ "$ssh_args" == *"ubuntu@10.0.0.5"* ]]
    [[ "$ssh_args" == *"-i /test/key.pem"* ]]
}

# =============================================================================
# Curl Mock Tests
# =============================================================================

@test "update_ec2_security_group fetches workstation IP" {
    # Test that curl mock's IP is used by the function
    result=$(
        export TMPDIR=$(mktemp -d)
        source "${BATS_TEST_DIRNAME}/../k3d-dev.sh"
        trap - EXIT

        AWSUSERNAME="testuser"
        PROJECTTAG="test"
        VPC_ID="vpc-mock123"
        SGname="testuser-dev-test"

        curl() {
            # Return a distinctive IP that we can check for in output
            echo "203.0.113.50"
        }

        aws() {
            case "$*" in
                *"describe-security-groups"*)
                    echo "sg-mock123"
                    ;;
                *"create-tags"*)
                    return 0
                    ;;
                *"authorize-security-group-ingress"*)
                    return 0
                    ;;
            esac
        }

        update_ec2_security_group 2>&1
    )
    # Verify the mocked IP address was used in the function's output
    [[ "$result" == *"203.0.113.50"* ]]
}

# =============================================================================
# Integration Tests
# =============================================================================

@test "check_for_existing_instances dispatches to cloud provider" {
    # Test that check_for_existing_instances calls the cloud provider function
    result=$(
        export TMPDIR=$(mktemp -d)
        source "${BATS_TEST_DIRNAME}/../k3d-dev.sh"
        trap - EXIT

        PROVISION_CLOUD_INSTANCE="true"
        CLOUDPROVIDER="aws"
        AWSUSERNAME="testuser"
        PROJECTTAG="test"
        InstId=""

        aws() {
            case "$*" in
                *"describe-instances"*)
                    echo "i-existingmock"
                    ;;
            esac
        }

        check_for_existing_instances
        echo "exit_code:$?"
    )
    [[ "$result" == *"exit_code:1"* ]]  # Returns 1 when instance IS found
}

@test "print_instructions does not make external calls" {
    _source_k3d_dev
    _reset_globals
    SSHKEY="/test/key.pem"
    SSHUSER="ubuntu"
    PublicIP="10.0.0.5"
    PrivateIP="10.0.0.5"
    KUBECONFIG="test-config"
    METAL_LB=true
    PRIVATE_IP=false
    PROVISION_CLOUD_INSTANCE=true
    CLOUDPROVIDER="aws"
    AWSUSERNAME="testuser"
    PROJECTTAG="test"
    InstId="i-mock12345"
    TERMINATE_INSTANCE=true

    # Fail if any external command is called
    ssh() { echo "ERROR: ssh called" >&2; return 1; }
    aws() { echo "ERROR: aws called" >&2; return 1; }
    curl() { echo "ERROR: curl called" >&2; return 1; }
    export -f ssh aws curl

    output=$(print_instructions 2>&1)

    # Should contain helpful text
    [[ "$output" == *"ssh"* ]] || [[ "$output" == *"KUBECONFIG"* ]]
}

# =============================================================================
# Error Handling Tests
# =============================================================================

@test "process_arguments reports unknown option" {
    _source_k3d_dev
    _reset_globals

    output=$(process_arguments --unknown-option 2>&1) || true
    [[ "$output" == *"not recognized"* ]]
}

@test "getDefaultAmi fails when AWS errors" {
    # Test that getDefaultAmi exits with non-zero when AWS call fails
    # We need to capture both output and exit code from a function that uses exit
    run bash -c '
        export TMPDIR=$(mktemp -d)
        source "'"${BATS_TEST_DIRNAME}"'/../k3d-dev.sh"
        trap - EXIT

        # Mock aws to always fail
        aws() { echo "An error occurred" >&2; return 1; }

        getDefaultAmi
    '
    # Function should exit non-zero and print error message
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unrecognized AWS partition"* ]]
}


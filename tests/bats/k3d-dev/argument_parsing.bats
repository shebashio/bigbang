#!/usr/bin/env bats
# Tests for: docs/reference/scripts/developer/k3d-dev.sh
# Focus: process_arguments flag parsing, validation, and mutual exclusion

load '../helpers/setup'

setup() {
  k3ddev_load
}

# ──────────────────────────────────────────────────────────────────────────────
# Defaults
# ──────────────────────────────────────────────────────────────────────────────

@test "defaults: METAL_LB is true" {
  process_arguments
  [[ "${METAL_LB}" == "true" ]]
}

@test "defaults: PRIVATE_IP is false" {
  process_arguments
  [[ "${PRIVATE_IP}" == "false" ]]
}

@test "defaults: BIG_INSTANCE is false" {
  process_arguments
  [[ "${BIG_INSTANCE}" == "false" ]]
}

@test "defaults: ATTACH_SECONDARY_IP is false" {
  process_arguments
  [[ "${ATTACH_SECONDARY_IP}" == "false" ]]
}

@test "defaults: TERMINATE_INSTANCE is true" {
  process_arguments
  [[ "${TERMINATE_INSTANCE}" == "true" ]]
}

@test "defaults: USE_WEAVE is false" {
  process_arguments
  [[ "${USE_WEAVE}" == "false" ]]
}

@test "defaults: ENABLE_OIDC is false" {
  process_arguments
  [[ "${ENABLE_OIDC}" == "false" ]]
}

@test "defaults: BASE_DOMAIN is dev.bigbang.mil" {
  process_arguments
  [[ "${BASE_DOMAIN}" == "dev.bigbang.mil" ]]
}

@test "defaults: SSHUSER is ubuntu" {
  process_arguments
  [[ "${SSHUSER}" == "ubuntu" ]]
}

@test "defaults: PROJECTTAG is default" {
  process_arguments
  [[ "${PROJECTTAG}" == "default" ]]
}

# ──────────────────────────────────────────────────────────────────────────────
# Simple flags
# ──────────────────────────────────────────────────────────────────────────────

@test "-b sets BIG_INSTANCE=true" {
  process_arguments -b
  [[ "${BIG_INSTANCE}" == "true" ]]
}

@test "-d sets action to destroy_instances" {
  process_arguments -d
  [[ "${action}" == "destroy_instances" ]]
}

@test "-K sets RESET_K3D=true" {
  process_arguments -K
  [[ "${RESET_K3D}" == "true" ]]
}

@test "-q sets QUIET=true" {
  process_arguments -q
  [[ "${QUIET}" == "true" ]]
}

@test "-T sets TERMINATE_INSTANCE=false" {
  process_arguments -T
  [[ "${TERMINATE_INSTANCE}" == "false" ]]
}

@test "-M sets METAL_LB=false" {
  process_arguments -M
  [[ "${METAL_LB}" == "false" ]]
}

@test "-O sets ENABLE_OIDC=true" {
  process_arguments -O
  [[ "${ENABLE_OIDC}" == "true" ]]
}

@test "-w sets USE_WEAVE=true" {
  process_arguments -w
  [[ "${USE_WEAVE}" == "true" ]]
}

@test "-r sets action to report_instances" {
  process_arguments -r
  [[ "${action}" == "report_instances" ]]
}

@test "-u sets action to update_instances" {
  process_arguments -u
  [[ "${action}" == "update_instances" ]]
}

# ──────────────────────────────────────────────────────────────────────────────
# Flags with arguments
# ──────────────────────────────────────────────────────────────────────────────

@test "-t VALUE sets PROJECTTAG" {
  process_arguments -t myproject
  [[ "${PROJECTTAG}" == "myproject" ]]
}

@test "-D VALUE sets BASE_DOMAIN" {
  process_arguments -D custom.example.com
  [[ "${BASE_DOMAIN}" == "custom.example.com" ]]
}

@test "-U VALUE sets SSHUSER" {
  process_arguments -U ec2-user
  [[ "${SSHUSER}" == "ec2-user" ]]
}

@test "-H VALUE sets PublicIP and disables cloud provisioning" {
  process_arguments -H 1.2.3.4
  [[ "${PublicIP}" == "1.2.3.4" ]]
  [[ "${PROVISION_CLOUD_INSTANCE}" == "false" ]]
}

# ──────────────────────────────────────────────────────────────────────────────
# Flag interactions
# ──────────────────────────────────────────────────────────────────────────────

@test "-a sets ATTACH_SECONDARY_IP=true and METAL_LB=false" {
  process_arguments -a
  [[ "${ATTACH_SECONDARY_IP}" == "true" ]]
  [[ "${METAL_LB}" == "false" ]]
}

@test "-H without -P sets PrivateIP equal to PublicIP" {
  process_arguments -H 1.2.3.4
  [[ "${PrivateIP}" == "1.2.3.4" ]]
}

@test "-H with -P uses the -P value for PrivateIP" {
  process_arguments -H 1.2.3.4 -P 10.0.0.5
  [[ "${PublicIP}" == "1.2.3.4" ]]
  [[ "${PrivateIP}" == "10.0.0.5" ]]
}

@test "combined flags: -t myproject -b -a -O" {
  process_arguments -t myproject -b -a -O
  [[ "${PROJECTTAG}" == "myproject" ]]
  [[ "${BIG_INSTANCE}" == "true" ]]
  [[ "${ATTACH_SECONDARY_IP}" == "true" ]]
  [[ "${ENABLE_OIDC}" == "true" ]]
}

@test "-d -t myproject sets both action and PROJECTTAG" {
  process_arguments -d -t myproject
  [[ "${action}" == "destroy_instances" ]]
  [[ "${PROJECTTAG}" == "myproject" ]]
}

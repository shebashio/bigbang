# helpers/setup.bash — Shared BATS setup for k3d-dev.sh tests
#
# Provides k3ddev_load() which sources k3d-dev.sh with a clean slate.
# Every .bats file should: load '../helpers/setup'

REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}" && git rev-parse --show-toplevel)"
K3D_DEV_SH="${REPO_ROOT}/docs/reference/scripts/developer/k3d-dev.sh"

k3ddev_load() {
  # Unset all globals that might leak between tests
  unset PublicIP PrivateIP SecondaryIP PrivateIP2 InstId
  unset SSHKEY AWSUSERNAME KUBECONFIG INIT_SCRIPT
  unset RUN_BATCH_FILE CLOUD_RECREATE_INSTANCE SecurityGroupId ARN
  unset PROVISION_CLOUD_INSTANCE CLOUDPROVIDER
  unset OIDC_ISSUER_URL OIDC_CLIENT_ID OIDC_USERNAME_CLAIM OIDC_GROUPS_CLAIM
  unset OIDC_PRESET ENABLE_OIDC
  unset METAL_LB PRIVATE_IP ATTACH_SECONDARY_IP USE_WEAVE BIG_INSTANCE
  unset TERMINATE_INSTANCE QUIET RESET_K3D BASE_DOMAIN SSHUSER PROJECTTAG

  # Provide a TMPDIR for the script's mktemp call
  export TMPDIR="${BATS_TEST_TMPDIR:-$(mktemp -d)}"

  # Source k3d-dev.sh — safe because main() is guarded by BASH_SOURCE check
  source "${K3D_DEV_SH}"

  # Clear k3d-dev.sh's EXIT trap to prevent interference with BATS
  trap - EXIT
}

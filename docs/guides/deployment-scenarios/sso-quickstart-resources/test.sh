#!/usr/bin/env bash
set -euo pipefail

REGISTRY1_USERNAME="Wyatt_Fry" ## Your Harbor username
REGISTRY1_PASSWORD="$HARBOR"   ## Your Harbor "CLI Secret" under "User Profile"
# REGISTRY1_PASSWORD="Your_Harbor_CLI_Secret" ## Your Harbor "CLI Secret" under "User Profile"

BIG_BANG_VERSION=$(curl -s https://repo1.dso.mil/big-bang/bigbang/-/raw/master/base/gitrepository.yaml | grep 'tag:' | awk '{print $2}')

function setup_host() {
    local env_vars=(
        CLUSTER_NAME="$1"
        K3D_IP="$2"
        REGISTRY1_USERNAME="$REGISTRY1_USERNAME"
        REGISTRY1_PASSWORD="$REGISTRY1_PASSWORD"
        BIG_BANG_VERSION="$BIG_BANG_VERSION"
    )
    local setup_files=(
        set_env_vars.sh
        install_prereqs.sh
        create_k3d_cluster.sh
        install_flux.sh
    )
    branch="refresh-keycloak-sso-quickstart-docs" ### TODO: Replace Following branch with master before merging
    red=$(tput setaf 1)
    normal=$(tput sgr0)
    for setup_file in "${setup_files[@]}"; do
        filepath="docs/guides/deployment-scenarios/sso-quickstart-resources/${setup_file}"
        url=https://repo1.dso.mil/big-bang/bigbang/-/raw/${branch}/${filepath}
        command="env $env_vars /bin/bash -c \"\$(curl -fsSL $url)\""
        printf "%-20s%-8s%-10s%-20s\n" "[$host]" "INFO" executing "$setup_file"
        if ! result="$(ssh "${host}" $command 2>&1)"; then
            printf "%-20s%-8s%-10s%-20s\n%s\n" "${red}[$host]" ERROR executing "$setup_file${normal}" "$result"
            exit 1
        else
            printf "%-20s%-8s%-10s%-20s\n" "[$host]" INFO done "$setup_file"
        fi
    done
}

for host in keycloak-cluster workload-cluster; do
    K3D_IP=$(ssh -G ${host}-cluster | awk '/^hostname / { print $2 }')
    setup_host "$host" "$K3D_IP" &
done
wait $(jobs -p)

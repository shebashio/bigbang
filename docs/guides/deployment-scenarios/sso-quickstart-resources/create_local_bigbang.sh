#!/usr/bin/env bash
set -euo pipefail

if [ -z "${REGISTRY_USERNAME}" ]; then
  echo Please set an environment variable REGISTRY_USERNAME with your registry1 / Harbor username
  exit 1
fi

if [ -z "${REGISTRY_PASSWORD}" ]; then
  echo Please set an environment variable REGISTRY_PASSWORD with your registry1 / Harbor CLI Secret
  exit 1
fi

docker ps &> /dev/null || (echo Docker is not running. Please start Docker and try again && exit 1)

cluster_name=bigbang-sso-quickstart

echo "Creating a k3d Kubernetes cluster called '$cluster_name' if none already exists..."

k3d cluster list | grep $cluster_name &> /dev/null || k3d cluster create $cluster_name \
  --agents 3 \
  -p80:80@loadbalancer \
  -p443:443@loadbalancer \
  --k3s-arg --disable=traefik@server:0 &> /dev/null
#  --k3s-arg --disable=traefik@server:0 \
#  --api-port 6443 &> /dev/null

config_path=$HOME/.kube/${cluster_name}-config
echo "Saving Kubernetes config file ${config_path}..."

k3d kubeconfig get $cluster_name > "$config_path"
KUBECONFIG="$config_path"

echo "Prefix your helm and kubectl commands with the following or add to your shell's rc file:"
echo "export KUBECONFIG=${config_path}"

echo 'Installing Flux...'

helm upgrade -i --create-namespace -n flux-system flux oci://ghcr.io/fluxcd-community/charts/flux2 &> /dev/null

echo 'Installing Big Bang with Keycloak enabled...'
bb='repo1.dso.mil/big-bang'
helm upgrade -i bigbang oci://registry1.dso.mil/bigbang/bigbang \
   -n bigbang \
   --create-namespace \
   --set registryCredentials.username=${REGISTRY_USERNAME} \
   --set registryCredentials.password=${REGISTRY_PASSWORD} \
   -f https://${bb}/bigbang/-/raw/master/tests/test-values.yaml \
   -f https://${bb}/bigbang/-/raw/master/chart/ingress-certs.yaml \
   -f https://${bb}/product/packages/keycloak/-/raw/main/docs/dev-overrides/keycloak-testing.yaml &> /dev/null
   # -f https://${bb}/product/packages/keycloak/-/raw/main/docs/dev-overrides/minimal.yaml \

echo 'Big Bang installed. Modify your /etc/hosts file then go to https://keycloak.dev.bigbang.mil/auth/admin in your browser'
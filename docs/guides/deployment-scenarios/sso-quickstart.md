# Auth Service and Keycloak SSO Quick Start Demo

[[_TOC_]]

# This overrides file is for deploying only the packages needed to test keycloak during renovate or other update/change work, and should be used in combination with the testing steps called out in docs/DEVELOPMENT_MAINTENANCE.md
# This is for deploying/testing with a local keycloak (keycloak.dev.bigbang.mil)
```shell
REGISTRY_USERNAME="YOUR HARBOR USERANME HERE"
REGISTRY_PASSWORD="YOUR HARBOR CLI TOKEN HERE"

k3d cluster list | grep bigbang || k3d cluster create bigbang \
  --agents 12 \
  -p80:80@loadbalancer \
  -p443:443@loadbalancer \
  --k3s-arg --disable=traefik@server:0 \
  --api-port 6443

k3d kubeconfig get bigbang > ./bigbangconfig
KUBECONFIG=./bigbangconfig

helm upgrade -i --create-namespace -n flux-system flux oci://ghcr.io/fluxcd-community/charts/flux2
bb='repo1.dso.mil/big-bang/bigbang/-/raw/master'
kc='repo1.dso.mil/big-bang/product/packages/keycloak/-/raw/main/docs/dev-overrides'
helm registry login https://registry1.dso.mil/  # Not sure if this is necessary
helm upgrade -i bigbang oci://registry1.dso.mil/bigbang/bigbang \
   -n bigbang \
   --create-namespace \
   --set registryCredentials.username=${REGISTRY_USERNAME} \
   --set registryCredentials.password=${REGISTRY_PASSWORD} \
   -f https://${bb}/tests/test-values.yaml \
   -f https://${bb}/chart/ingress-certs.yaml \
   -f https://${kc}/minimal.yaml \
   -f https://${kc}/keycloak-testing.yaml
```
the customer has access to the granular day-to-day activity, they need a high level overview of your accomplishments
what does it mean, why is it important
what OKR(s) does it align with, what core problems does your work address (e.g. kubernetes is difficult)
written so that a project manager, non-engineer or contract person can understand
"I did X and the benefit of that is Y"
what does, e.g. unit tests, mean long-term for the project? stability, reliability, etc
if you're wondering if a task is really worth doing, ask Chris
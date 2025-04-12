# Upgrading from Istio Operator to Helm based Istio
  
### Timeline
- The new Istio Helm packages: [istio-core](https://repo1.dso.mil/big-bang/product/packages/istio-core) and [istio-gateway](https://repo1.dso.mil/big-bang/product/packages/istio-gateway) are *Beta* in [Big Bang 2.51](https://repo1.dso.mil/big-bang/bigbang/-/releases)
-  These packages will be GA/stable in 2.52 (or 2.53)
-  The [istio-operator](https://repo1.dso.mil/big-bang/product/packages/istio-operator) and [istio-controlplane](https://repo1.dso.mil/big-bang/product/packages/istio-controlplane) packages will be completely removed and no longer available in Big Bang in 3.0
- In order to continue using Istio as a part of Big Bang you must migrate from operator to helm in BB 2.52 (or 2.53)


## Migration Process  
  
Istio can be migrated from the old operator packages to the new helm-based packages in-place with a few steps.
### Step 1 : Swap `istio` for `istioCore`
Disable the old istio package and enable the new istioCore package:
```yaml
istioOperator:
  enabled: true
istio:
  enabled: false
  
istioCore:
  enabled: true
istioGateway:
  enabled: false
```
Give the cluster a few minutes for all helm releases to become `ready`.

### Step 2 : Disable `istioOperator` and enable `istioGateway`  
  
Removal of the operator and the enablement of the new gateway package reinstantiates cluster gateways.  
  
```yaml
istioOperator:
  enabled: false
istio:
  enabled: false
  
istioCore:
  enabled: true
istioGateway:
  enabled: true
```
When migrating gateway configurations, see [the examples here](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/chart/values.yaml#L205-269) as a reference to format values.  
  
After all helm releases become `ready` once again, verify gateway(s) recieves an external IP:
```bash
kubectl get svc -n istio-gateway
NAME                  TYPE         CLUSTER-IP    EXTERNAL-IP  PORT(S)                                    
public-ingressgateway LoadBalancer 10.43.110.109 172.16.88.88 15021:31155/TCP,80:31302/TCP,443:31046/TCP 
```
The migration process is now complete.  
  
## Troubleshooting Steps
  
Below are a few remedies if the migration did not go as smoothly as expected.  
  
### Services are unreachable:
```
upstream connect error or disconnect/reset before headers. retried and the latest reset reason: remote connection failure, transport failure reason: TLS_error:|268435581:SSL routines:OPENSSL_internal:CERTIFICATE_VERIFY_FAILED:TLS_error_end
```
To resolve this issue, cycle all Istio injected pods allowing their reconnection to the new service mesh.  
  
This simple bash script will iterate through all `istio-injected` namespaces and recycle pods:
```bash
# in istio-injected namespaces, recycle pods
for namespace in `kubectl get ns -o custom-columns=:.metadata.name --no-headers -l istio-injection=enabled`
do
    echo -e "\n♻️ recycling pods in namespace: $namespace"
    for pod in `kubectl get pods -o custom-columns=:.metadata.name --no-headers -n $namespace`
    do 
        kubectl delete pod $pod -n $namespace
    done
done
```














### Optionally reconcile Helm Releases
It may (but unlikely) be necessary to synchronize the helm releases managed by Flux. Typically, this can occur when a Gitops deployment of Big Bang has its helm resources get out of sync during an upgrade.  
  
The `flux` CLI must be [installed locally](https://fluxcd.io/flux/installation/) -- on macOS and Linux:
```bash
brew install fluxcd/tap/flux
```
This bash script iterates through all helm releases managed by Big Bang and has `flux` initiate a [reconciliation](https://fluxcd.io/flux/cmd/flux_reconcile_helmrelease) on each HR one by one:
```bash
# reconcile all of big bang's helm releases w/ flux
for hr in `kubectl get hr --no-headers -n bigbang | awk '{ print $1 }'`
do
    echo -e '\n☸️ reconciling hr:' $hr
    flux reconcile hr $hr -n bigbang --with-source
done
```

At this point all services in the cluster should be reachable via the new service mesh.  

## Other Notes

- The Istio Operator has reached its end of life and does not support versions of Istio after 1.23
- An LTS release, Istio 1.23 is only supported [through May 2025](https://istio.io/latest/docs/releases/supported-releases/#:~:text=1.25%2C%201.26%2C%201.27-,1.23,-Yes)
- In order to continue utilizing Istio in Big Bang releases beyond 3.0, this migration is required
- An upgrade to version 1.25 of Istio will soon follow in version 3.1 or version 3.2 of Big Bang in mid-2025
- A rollback from Helm Istio to Operator Istio is possible by reversing the migration process above
- [Diagnostic Tools for Istio](https://istio.io/latest/docs/ops/diagnostic-tools) and [Troubleshooting tips](https://github.com/istio/istio/wiki/Troubleshooting-Istio) can be of assistance for troubled migrations













After a few minutes, all pods in both the `istio-system` and `istio-operator` namespaces will have terminated. However, due to Istio's finalizer, the `istio-system` namespace will be stuck in the _**terminating**_ state.  
  
Force the deletion of this namespace:
```bash
kubectl get ns istio-system -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/istio-system/finalize" -f -
```
Both Istio namespaces are now removed yet other remnants still linger, not limited to, but including custom resources. Remove them as they will be recreated via the helm deployment of Istio. The quickest way to do this is by using the [istioctl CLI tool](https://istio.io/latest/docs/ops/diagnostic-tools/istioctl/).  
  
On macOS or Linux install it with:
```bash
brew install istioctl
```
To complete the removal of remaining Istio components, purge as per [Istio's documentation](https://istio.io/latest/docs/setup/install/istioctl/#uninstall-istio):
```bash
istioctl uninstall --purge
```
Accept the prompt to proceed:
```bash
All Istio resources will be pruned from the cluster
Proceed? (y/N) y
  Removed admissionregistration.k8s.io/v1, Kind=MutatingWebhookConfiguration/istio-revision-tag-default..
  Removed admissionregistration.k8s.io/v1, Kind=MutatingWebhookConfiguration/istio-sidecar-injector..
  Removed admissionregistration.k8s.io/v1, Kind=ValidatingWebhookConfiguration/istio-validator-istio-system..
  Removed admissionregistration.k8s.io/v1, Kind=ValidatingWebhookConfiguration/istiod-default-validator..
  Removed rbac.authorization.k8s.io/v1, Kind=ClusterRole/istio-reader-clusterrole-istio-system..
  Removed rbac.authorization.k8s.io/v1, Kind=ClusterRole/istiod-clusterrole-istio-system..
  Removed rbac.authorization.k8s.io/v1, Kind=ClusterRole/istiod-gateway-controller-istio-system..
  Removed rbac.authorization.k8s.io/v1, Kind=ClusterRoleBinding/istio-reader-clusterrole-istio-system..
  Removed rbac.authorization.k8s.io/v1, Kind=ClusterRoleBinding/istiod-clusterrole-istio-system..
  Removed rbac.authorization.k8s.io/v1, Kind=ClusterRoleBinding/istiod-gateway-controller-istio-system..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/authorizationpolicies.security.istio.io..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/destinationrules.networking.istio.io..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/envoyfilters.networking.istio.io..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/gateways.networking.istio.io..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/peerauthentications.security.istio.io..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/proxyconfigs.networking.istio.io..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/requestauthentications.security.istio.io..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/serviceentries.networking.istio.io..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/sidecars.networking.istio.io..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/telemetries.telemetry.istio.io..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/virtualservices.networking.istio.io..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/wasmplugins.extensions.istio.io..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/workloadentries.networking.istio.io..
  Removed apiextensions.k8s.io/v1, Kind=CustomResourceDefinition/workloadgroups.networking.istio.io..
✔ Uninstall complete 
```

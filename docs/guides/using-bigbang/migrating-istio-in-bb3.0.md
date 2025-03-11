# Upgrading from the Istio Operator to Helm based Istio 

### *The new Istio Helm packages are BETA in Big Bang 2.x and will be stable in 3.0*

### Step 1 : Remove Istio from your current deployment
Before upgrading to the new Helm-based Istio packages, first disable the Istio and Istio's Operator packages:
```yaml
istio:
  enabled: false
istioOperator:
  enabled: false
```
After a few minutes, all pods in both the `istio-system` and `istio-operator` namespaces will have terminated. However, due due to Istio's finalizer, the `istio-system` namespace will be stuck in the `terminating` state.  
  
Force the deletion of this namespace:
```bash
kubectl get ns istio-system -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/istio-system/finalize" -f -
```
Both Istio namespaces are now removed yet other remnants of Istio still linger in the cluster including custom resources. Remove them as they will be recreated via the helm deployment of Istio. The quickest way to do this is by using the [istioctl CLI tool](https://istio.io/latest/docs/ops/diagnostic-tools/istioctl/).  
  
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

### Step 2 : Deploy the new Helm Istio package
Enabling the Helm based version of Istio entails enabling the `istioCore` package that provides both the `istio-base` and `istiod` charts. The `istioGateway` package provides the ability to add one or more egress gateways:
```yaml
istioCore:
  enabled: true
istioGateway:
  enabled: true
```
When migrating gateway configurations from Operator to Operatorless, see [the examples here](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/chart/values.yaml#L209-263) as a reference to format values.  
  
After deployment, check that new gateway recieves an external IP (from MetalLB or AWS LB) with:
```bash
kubectl get svc -n istio-gateway
NAME                  TYPE         CLUSTER-IP    EXTERNAL-IP  PORT(S)                                    
public-ingressgateway LoadBalancer 10.43.110.109 172.16.88.88 15021:31155/TCP,80:31302/TCP,443:31046/TCP 
```
Notice that services are now unreachable with errors like:
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
It may be necessary, but not likely, to synchronize helm releases managed by Flux. Typically, this can occur when a Gitops deployment of Big Bang sees its helm resources get out of sync during an upgrade.  
  
This step requires `flux` to be [installed locally](https://fluxcd.io/flux/installation/). Install it on macOS and Linux with:
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
### Enjoy your new helm based deploymenbt of Istio!
At this point all services in the cluster should be reachable via the new service mesh. 

# Other Notes

- The Istio Operator has reached its end of life not supporting versions of Istio after 1.23
- An LTS release, Istio 1.23 is only supported [through May 2025](https://istio.io/latest/docs/releases/supported-releases/#:~:text=1.25%2C%201.26%2C%201.27-,1.23,-Yes)
- The migration from Operator to Helm maintains a consistent version 1.23 to reduce the complexity of the process
- In order to continue utilizing Istio in Big Bang releases >=3.0 this migration is required
- An upgrade to version 1.24 of Istio will soon follow in version 3.1 or version 3.2 of Big Bang in mid-2025
- A rollback from Helm Istio to Operator Istio is possible by reversing the migration steps process
- [Diagnostic Tools for Istio](https://istio.io/latest/docs/ops/diagnostic-tools) and [Troubleshooting tips](https://github.com/istio/istio/wiki/Troubleshooting-Istio) can be of assistance for troubled migrations
- Similarly, there is [an Istio manifest tool](https://github.com/istio/istio/pull/52281) that can be used to compare pre and post upgrades
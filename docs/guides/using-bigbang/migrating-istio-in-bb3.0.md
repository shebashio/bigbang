# Upgrading from the Istio Operator to Helm based Istio 

### *The new service mesh is BETA in Big Bang 2.x and is planned to be completely stable in 3.0!*

### Step 1 : Remove Istio from your deployment
Before upgrading to version 3.0 of Big Bang with the new Helm-based Istio packages, we first need to disable Istio and Istio's Operator packages in our 2.x deployment of Big Bang. We do this by disabling the two obsolete [Istio packages in our Gitops configuration](https://repo1.dso.mil/kipten/template/-/blob/main/package-strategy/configmap.yaml?ref_type=heads#L18-22).
```yaml
istio:
  enabled: false
istioOperator:
  enabled: false
```
After a few minutes, all pods in both the `istio-system` and `istio-operator` namespaces should have terminated. However, due due to Istio's finalizer, it's likely that the `istio-system` namespace will be stuck in the `terminating` state. We can force the deletion of this namespace with the following:
```bash
kubectl get ns istio-system -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/istio-system/finalize" -f -
```
Both namespaces are now removed yet other remnants of Istio still linger in the cluster including custom resources. These also need to be removed as they will be re-instantiated via the helm deployment of Istio. There are various methods to accomplish this feat, but by far the easiest way to do this is by using the [istioctl CLI tool](https://istio.io/latest/docs/ops/diagnostic-tools/istioctl/).  
  
If you're on Mac or Linux, you can quickly install it with:
```bash
brew install istioctl
```
To complete the removal of the Istio remnants, purge [as per Istio's documentation](https://istio.io/latest/docs/setup/install/istioctl/#uninstall-istio):
```bash
istioctl uninstall --purge
```
Accept the prompt and these remnants are removed:
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

### Step 2 : Deploy the new Helm based version of Istio
Enabling the Helm based version of Istio entails enabling the `istioCore` package that provides both the `istio-base` and `istiod` charts. The `istioGatewayPublic` package provides the default ingress gateway for most packages and the `istioGatewayPassthrough` provides a secondary non-TLS gated gateway for specific apps that require this like Keycloak.
```yaml
istioCore:
  enabled: true
istioGatewayPublic:
  enabled: true
istioGatewayPassthrough:
  enabled: true
```
You can check that new gateway recieves an external IP (from MetalLB or AWS LB) with:
```bash
kubectl get svc -n istio-gateway
NAME                  TYPE         CLUSTER-IP    EXTERNAL-IP  PORT(S)                                    
public-ingressgateway LoadBalancer 10.43.110.109 172.16.88.88 15021:31155/TCP,80:31302/TCP,443:31046/TCP 
```
You'll notice at this point that services are unreachable with errors like:
```
upstream connect error or disconnect/reset before headers. retried and the latest reset reason: remote connection failure, transport failure reason: TLS_error:|268435581:SSL routines:OPENSSL_internal:CERTIFICATE_VERIFY_FAILED:TLS_error_end
```
The reason for this is becuase we now need to cycle istio-injected pods so that they connect to the new service mesh. The simple bash script below will iterate through all istio-injected namespaces and cycles all pods therein:
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
You may also need to initiate a reconciliation to all of Big Bang's helm releases managed by `flux`.  
  
This step does require that `flux` is [installed locally](https://fluxcd.io/flux/installation/). Linux and Mac users can simply:
```bash
brew install fluxcd/tap/flux
```
This simple bash script will iterate through all of Big Bang managed Helm release and prompt `flux` to [reconcile](https://fluxcd.io/flux/cmd/flux_reconcile_helmrelease) each HR one at a time waiting for them to complete. Typically, this can be useful when managing a Gitops deployment of Big Bang during upgrades or when helm and its dependencies get out of sync.
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

- The above migration from Operator Istio to Helm Istio maintains a consistent version (v1.23) of Istio to reduce the complexity of the process.
- Operator Istio does not support any versions of Istio that follow after version 1.23 and this specific version of Istio, an LTS release, is only supported [through May 2025](https://istio.io/latest/docs/releases/supported-releases/#:~:text=1.25%2C%201.26%2C%201.27-,1.23,-Yes). 
- In order to continue utilizing Istio with Big Bang in versions >=3.0 this migration is required and upgrade to v1.24 of Istio will soon follow in a near term Big Bang release, possibly in 3.1 or 3.2 in mid-2025.
- Rollback from Helm Istio to Operator Istio -- A reversal of the above workflow is possible to revert back to the Operator deployment of Istio from the helm based deployment

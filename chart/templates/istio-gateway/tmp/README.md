# Main issue with istio at the moment

https://repo1.dso.mil/big-bang/bigbang/-/issues/2257

# Overrides and other yaml's in this folder....

```bash
draft-gateway.yaml
draft-kiali-vs.yaml
gateway-from-istio-operator-deployment.yaml
kiali-vs-from-istio-operator-deployment.yaml
overrides-istio-sandbox.yaml
```

# in progress MRs

- `istio-sandbox` BB MR: https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/4906
- `dev` branch istio-base: https://repo1.dso.mil/big-bang/apps/sandbox/istio-base/-/merge_requests/5
- `dev` branch istiod: https://repo1.dso.mil/big-bang/apps/sandbox/istiod/-/merge_requests/20
- `dev` branch istio-gateway: https://repo1.dso.mil/big-bang/apps/sandbox/istio-gateway/-/merge_requests/9
- `dev` branch kiali: https://repo1.dso.mil/big-bang/product/packages/kiali/-/merge_requests/256/diffs

# a helm deployment of operatorless istio

applied yamls are in the READMEs of the MRs above for reg credentials

```
#!/bin/bash

pushd ~/repos/istio-base && \
helm upgrade \
    --install istio-base ./chart \
    --create-namespace \
    --namespace istio-system && \

popd && pushd ~/repos/istiod && \
helm upgrade \
    --install istiod ./chart \
    --namespace istio-system && \
kubectl apply -f ~/repos/registry1-istiod.yaml && \

popd && pushd ~/repos/istio-gateway && \
helm upgrade \
    --install istio-ingressgateway ./chart \
    --create-namespace \
    --namespace istio-ingress && \
kubectl apply -f ~/repos/registry1-istio-gateway.yaml && \

popd && pushd ~/repos/kiali && \
    helm upgrade \
    --install kiali ./chart \
    --create-namespace \
    --namespace kiali && \
kubectl apply -f ~/repos/registry1-kiali.yaml && \
kubectl label ns kiali istio-injection=enabled && \

popd
```
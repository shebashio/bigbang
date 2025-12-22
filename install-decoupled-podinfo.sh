# create podinfo namespace
kubectl create namespace podinfo

# ensure it is istio injected
kubectl label namespace podinfo istio-injection=enabled --overwrite

# apply manifests
kubectl apply -f decoupled-podinfo/manifests.yaml
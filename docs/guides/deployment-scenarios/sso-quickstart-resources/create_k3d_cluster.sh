/usr/bin/env bash
set -euo pipefail

IMAGE_CACHE=${HOME}/.k3d-container-image-cache
mkdir -p "${IMAGE_CACHE}"
k3d cluster create "$CLUSTER_NAME" \
  --k3s-arg "--tls-san=$K3D_IP@server:0" \
  --volume /etc/machine-id:/etc/machine-id \
  --volume "${IMAGE_CACHE}":/var/lib/rancher/k3s/agent/containerd/io.containerd.content.v1.content \
  --k3s-arg "--disable=traefik@server:0" \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer \
  --api-port 6443
sed "s/0.0.0.0/$K3D_IP/" ~/.kube/config > ~/.kube/${CLUSTER_NAME}-config
# Explanation:
# sed = stream editor
# -i s/.../.../   (i = inline), (s = substitution, basically cli find and replace)
# / / / are delimiters the separate what to find and what to replace.
# $K3D_IP, is a variable with $ escaped, so the var will be processed by the remote VM.
# This was done to allow kubectl access from a remote machine.

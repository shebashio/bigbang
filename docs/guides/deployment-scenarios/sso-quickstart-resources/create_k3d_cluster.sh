#!/usr/bin/env bash
set -euo pipefail

if [[ $(docker ps | grep k3d | wc -l) -gt 0 ]]; then
  echo A k3d cluster seems to already exist, exiting
  exit 0
fi


K3D_IP=$(curl icanhazip.com)
IMAGE_CACHE=${HOME}/.k3d-container-image-cache
mkdir -p "${IMAGE_CACHE}"
k3d cluster create "$(hostname)" \
  --k3s-arg "--tls-san=$K3D_IP@server:0" \
  --volume /etc/machine-id:/etc/machine-id \
  --volume "${IMAGE_CACHE}":/var/lib/rancher/k3s/agent/containerd/io.containerd.content.v1.content \
  --k3s-arg "--disable=traefik@server:0" \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer \
  --api-port 6443

# Copy the config replacing 0.0.0.0 with the VM's external IP address so you can access the cluster from your machine
sed "s/0.0.0.0/$K3D_IP/" ~/.kube/config > "$HOME/.kube/$(hostname)-config"

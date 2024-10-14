#!/usr/bin/env bash
set -euo pipefail

# Remove the following lines if they already exist
for x in BIG_BANG_VERSION REGISTRY1_USERNAME REGISTRY1_PASSWORD CLUSTER_NAME K3D_IP; do
  sudo sed -i "/.*${x}.*/d" ~/.bashrc
done

sudo hostnamectl set-hostname "$CLUSTER_NAME"

lines_in_file=(
    "export CLUSTER_NAME=\"$CLUSTER_NAME\""
    "export BIG_BANG_VERSION=\"$BIG_BANG_VERSION\""
    "export K3D_IP=\"$K3D_IP\""
    "export REGISTRY1_USERNAME=\"$REGISTRY1_USERNAME\""
    "export REGISTRY1_PASSWORD=\"$REGISTRY1_PASSWORD\""
)

for line in "${lines_in_file[@]}"; do
  grep -qF "${line}" ~/.bashrc || sed -i "1i\\${line}" "$HOME/.bashrc"
done



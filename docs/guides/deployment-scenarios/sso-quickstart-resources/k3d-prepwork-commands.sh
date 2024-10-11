#!/usr/bin/env bash
set -exuo pipefail

# Remove the following lines if they already exist
for x in BIG_BANG_VERSION REGISTRY1_USERNAME REGISTRY1_PASSWORD CLUSTER_NAME K3D_IP; do
  sudo sed -i "/.*${x}.*/d" ~/.bashrc
done

lines_in_file=(
    "export PS1=\"\[\033[01;32m\]\u@${CLUSTER_NAME}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
    "export CLUSTER_NAME=\"$CLUSTER_NAME\""
    "export BIG_BANG_VERSION=\"$BIG_BANG_VERSION\""
    "export K3D_IP=\"$K3D_IP\""
    "export REGISTRY1_USERNAME=\"$REGISTRY1_USERNAME\""
    "export REGISTRY1_PASSWORD=\"$REGISTRY1_PASSWORD\""
)

for line in "${lines_in_file[@]}"; do
  grep -qF "${line}" ~/.bashrc || echo "${line}" >> ~/.bashrc
done

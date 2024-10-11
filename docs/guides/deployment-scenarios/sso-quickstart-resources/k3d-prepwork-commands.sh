#!/usr/bin/env bash
set -exuo pipefail

# Remove the following lines if they already exist
sudo sed -i "/.*BIG_BANG_VERSION.*/d"      ~/.bashrc
sudo sed -i "/.*REGISTRY1_USERNAME.*/d"    ~/.bashrc
sudo sed -i "/.*REGISTRY1_PASSWORD.*/d"    ~/.bashrc

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

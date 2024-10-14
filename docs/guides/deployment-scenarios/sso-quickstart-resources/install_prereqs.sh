#!/usr/bin/env bash
set -euo pipefail

# Configure OS
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192
sudo sysctl --load
sudo modprobe xt_REDIRECT
sudo modprobe xt_owner
sudo modprobe xt_statistic
printf "xt_REDIRECT\nxt_owner\nxt_statistic\n" | sudo tee -a /etc/modules
sudo swapoff -a

# Install git
sudo apt install git -y

# Install docker (note we use escape some vars we want the remote linux to substitute)
sudo apt update -y && sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt update -y && sudo apt install docker-ce docker-ce-cli containerd.io -y && sudo usermod --append --groups docker "$USER"

cd /usr/local/bin

# Install k3d
curl https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
k &>/dev/null || sudo ln -s /usr/local/bin/kubectl /usr/local/bin/k

# Install kustomize
kustomize &>/dev/null || curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | sudo bash

# Install helm
helm &>/dev/null || curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "$0" $(hostname) INFO: completed installation, verifying...

function check() {
  ${*} &>/dev/null &&
    echo "$(hostname) SUCCESS: '${*}' returned non-failure exit code" ||
    echo -e "\033[31m$(hostname) ERROR:   '${*}' returned failure exit code '$?'. Verify installation or attempt re-install.\033[0m"
}

check_inputs=(
  'docker ps'
  'k3d version'
  'which kubectl'
  'kustomize version'
  'helm version'
)

for i in "${check_inputs[@]}"; do
  check "$i"
done

echo "$0" $(hostname) INFO: checks complete

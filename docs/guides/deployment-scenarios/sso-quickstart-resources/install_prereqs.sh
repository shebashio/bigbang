/usr/bin/env bash
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
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y && sudo apt install docker-ce docker-ce-cli containerd.io -y && sudo usermod --append --groups docker "$USER"

cd /usr/local/bin

# Install k3d
curl https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo ln -s /usr/local/bin/kubectl /usr/local/bin/k

# Install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

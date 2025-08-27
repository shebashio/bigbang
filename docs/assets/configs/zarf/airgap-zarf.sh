#!/bin/bash

# this script creates a zarf export of bigbang by:
# - parsing the results from zarf tools get-creds and substitutes values in the envsubst file,
# - creating the zst file and inspecting the file to make sure it worked correctly
# - pushing the zst to k3d network
# - optionally - shut down everything

# allocate ubuntu 24 EC2 instance

# mkdir ~/airgap directory on EC2
# `chmod u+wx airgap` to have user rights to create files
# mkdir airgap/config

# given an ssh command to connect to EC2 adjust the scp commands and copy the 4 files over:
#ssh -i "airgap-bigbang.pem" ubuntu@ec2-182-30-21-151.us-gov-east-1.compute.amazonaws.com
#scp -i ~/Downloads/airgap-bigbang.pem  airgap-zarf.sh ubuntu@ec2-182-30-21-151.us-gov-east-1.compute.amazonaws.com:~/airgap
#scp -i ~/Downloads/airgap-bigbang.pem  bb-zarf-credentials.template.yaml ubuntu@ec2-182-30-21-151.us-gov-east-1.compute.amazonaws.com:~/airgap
#scp -i ~/Downloads/airgap-bigbang.pem  zarf.yaml ubuntu@ec2-182-30-21-151.us-gov-east-1.compute.amazonaws.com:~/airgap
#scp -i ~/Downloads/airgap-bigbang.pem  config/kyverno.yaml ubuntu@ec2-182-30-21-151.us-gov-east-1.compute.amazonaws.com:~/airgap/config

# for testing,
# Install k8s
#	sudo snap install k8s --classic
#	sudo k8s bootstrap
#	sudo k8s status
#	# wait for ready
#	sudo k8s kubectl get all --all-namespaces
#
# Install docker
#	sudo apt update
#	sudo apt install apt-transport-https ca-certificates curl software-properties-common
#	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
#	sudo apt install docker-ce
#	sudo systemctl status docker # see it’s there
#
# Install k3d
#	wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
#
# Install kubectl
#	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"  	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256”
#	echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
#	sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
#	kubectl version --client
#
# run sudo -s to enable all of the dependencies needed

ZARF_CREDS_TEMP_FILE="temp file used to store zarf credentials"
ZARF_PULL="zarf_pull password from zarf credentials"
ZARF_GIT_USER="zarf_git_user password from zarf credentials"

function make_sure_can_write_local_file() {
  sudo touch .test_writable_file 2>/dev/null
  if [ $? -eq 0 ]; then
    # File can be created in the current directory
    sudo rm .test_writable_file # Clean up the temporary file
  else
    echo "File cannot be created in the current directory (permission denied or other issue)."
    exit 1
  fi
}

# do we need to install docker?
function start_docker() {
  if command -v docker &> /dev/null; then
      echo "Docker is installed."
  else
      echo "Docker is missing."
      exit 1
  fi

  if sudo systemctl is-active --quiet docker; then
    echo "Docker daemon is running."
    return
  fi

  # "Docker daemon is not running. Attempting to start Docker..."
  sudo systemctl start docker

  # Optional: Verify if Docker started successfully
  if sudo systemctl is-active --quiet docker; then
    echo "Docker daemon started successfully."
    return
  fi

  echo "Failed to start Docker daemon. Please check logs for errors."
  exit 1
}

function install_kubernetes() {
  if command -v kubectl &> /dev/null; then
      echo "kubectl is installed."
# does k3d set things up correctly for the new cluster?
#      local kubeconfig_file="$PWD/kube.config"
#      if [ ! -f "$kubeconfig_file" ]; then
#        echo "./kube-config missing - creating same"
#        sudo kubectl config view > "$kubeconfig_file"
#        export KUBECONFIG=$kubeconfig_file
#      fi
      return
  fi
  echo "Kubectl is not installed"
  exit 1
}

function create_cluster() {
  if command -v k3d &> /dev/null; then
      # "k3d is installed."
      if sudo k3d cluster list | grep -q "mycluster"; then
         # "k3d cluster '${CLUSTER_NAME}' exists."
         sudo k3d cluster delete mycluster
         while sudo k3d cluster list | grep -q "mycluster"; do
           sleep 5
         done
      fi

      sudo k3d cluster create mycluster
      if [ $? -ne 0 ]; then
          echo "k3d cluster create failed."
          exit 1
      fi
      return
  fi
  echo "k3d is not installed"
  exit 1
}

function zarf_init() {
  if [ ! -f "zarf" ]; then
    ZARF_VERSION=$(curl -sIX HEAD https://github.com/zarf-dev/zarf/releases/latest | grep -i ^location: | grep -Eo 'v[0-9]+.[0-9]+.[0-9]+')
    curl -sL "https://github.com/zarf-dev/zarf/releases/download/${ZARF_VERSION}/zarf_${ZARF_VERSION}_Linux_amd64" -o zarf
    chmod +x zarf
  fi
  ./zarf init --components=git-server --confirm
  if [ $? -ne 0 ]; then
      echo "zarf init failed.  Re-running zarf init"
      ./zarf init --components=git-server
      if [ $? -ne 0 ]; then
        echo "Re-running zarf init failed."
        exit 1
      fi
  fi
}

function get_zarf_credentials() {
#% zarf tools get-creds
#
#2025-08-25 14:17:26 INF waiting for cluster connection
#
#     Application          | Username           | Password                                 | Connect               | Get-Creds Key
#     Registry             | zarf-push          | OypipimHt~e0L0TDFcMpUSMb                 | zarf connect registry | registry
#     Registry (read-only) | zarf-pull          | MBd1sg8GIMICq8QlbDLOmKPd                 | zarf connect registry | registry-readonly
#     Git                  | zarf-git-user      | !jO196159n1-YPk3WQnob50L                 | zarf connect git      | git
#     Git (read-only)      | zarf-git-read-user | xPwtiKAw9hreRTdQTgHNGqSd                 | zarf connect git      | git-readonly
#     Artifact Token       | zarf-git-user      | 97b5254e39c1eec884944b18940929ac22494cee | zarf connect git      | artifact

# remove escape characters in the output for font coloring
  ZARF_CREDS_TEMP_FILE=$(mktemp)
  ./zarf tools get-creds | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' > "$ZARF_CREDS_TEMP_FILE"
  if [ $? -ne 0 ]; then
      echo "zarf tools get-creds failed."
      exit 1
  fi
}

function extract_passwords() {
  # using pipe delimiter, pull the 3rd column(Password) from the row with the
  # Username we are looking for
  local temp_file="$ZARF_CREDS_TEMP_FILE"
  if [ -n "$1" ]; then
    temp_file=$1
  fi
  local zarf_pull_plus=$(grep "zarf-pull" "$temp_file" | cut -d'|' -f3)
  # trim spaces before and after
  ZARF_PULL=$(echo "$zarf_pull_plus" | xargs )

  local zarf_git_user_plus=$(grep -m 1 "zarf-git-user" "$temp_file" | cut -d'|' -f3)
  ZARF_GIT_USER=$(echo "$zarf_git_user_plus" | xargs )
}

function build_zarf_credentials() {
  # substitute the credentials through the template
  export ZARF_PULL
  export ZARF_GIT_USER
  envsubst < bb-zarf-credentials.template.yaml > bb-zarf-credentials.yaml
}

function create_zarf_package() {
  # create the zst file, zarf-package-bigbang-amd64.tar.zst
  # the filename is built from aspects of the credentials file
  ./zarf package create . --confirm
  if [ $? -ne 0 ]; then
      echo "zarf package create failed."
      exit 1
  fi
}

function inspect_zarf_package() {
  # make sure it worked - inspect the definition portion of the file
  ./zarf package inspect definition zarf-package-bigbang-amd64.tar.zst
  if [ $? -ne 0 ]; then
      echo "zarf package inspection failed."
      exit 1
  fi
}

function deploy_zarf_package() {
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo "amd64 package cannot be deployed on arm64"
    exit 1
  fi
  ./zarf package deploy zarf-package-bigbang-amd64.tar.zst --confirm
  if [ $? -ne 0 ]; then
      echo "zarf package deploy failed."
      exit 1
  fi
}

function close_down() {
  # temp file created on each zarf init
  local temp_file="$ZARF_CREDS_TEMP_FILE"
  if [ -n "$1" ]; then
    temp_file=$1
  fi
  sudo rm -f $temp_file

  # credentials file we create to invoke zarf
  sudo rm -f bb-zarf-credentials.yaml

  # the zarf package we create with bigbang
  sudo rm -f zarf-package-bigbang-amd64.tar.zst

  # if docker is running
  if command -v docker &> /dev/null; then
    # if we created a cluster
    if sudo k3d cluster list | grep -q "mycluster"; then
      sudo k3d cluster delete mycluster
    fi
  fi

  ./zarf destroy --confirm
}

function main() {
  if [ "$#" -ne 0 ]; then
    "$1" $2
  else
    make_sure_can_write_local_file
    start_docker
    install_kubernetes
    create_cluster
    zarf_init
    get_zarf_credentials
    extract_passwords
    build_zarf_credentials
    create_zarf_package
    inspect_zarf_package
    deploy_zarf_package
    #close_down
    echo "AirGap zarf deployment of BigBang complete"
  fi
}

main "$@"


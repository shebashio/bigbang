#!/bin/bash

# this script creates a zarf export of bigbang by:
# - parsing the results from zarf tools get-creds and substitutes values in the envsubst file,
# - creating the zst file and inspecting the file to make sure it worked correctly
# - pushing the zst to k3d network
# - optionally - shut down everything

# run k3d-dev.sh -b
# to setup an ec2 instance with standard tools/packages available

# ssh to the instance
# mkdir ~/airgap directory on EC2
# `chmod u+wx airgap` to have user rights to create files
# mkdir airgap/config

# cd /Users/dantoomey/workspace/bigbang/docs/assets/scripts/developer/

# given an ssh command to connect to EC2 adjust the scp commands and copy the 4 files over:
#scp -i /Users/dantoomey/.ssh/dan.toomeyomnifederal.com-dev-default.pem airgap-zarf.sh ubuntu@18.253.144.201:~/airgap
#scp -i /Users/dantoomey/.ssh/dan.toomeyomnifederal.com-dev-default.pem zarf.yaml ubuntu@18.253.144.201:~/airgap
#scp -i /Users/dantoomey/.ssh/dan.toomeyomnifederal.com-dev-default.pem config/kyverno.yaml ubuntu@18.253.144.201:~/airgap/config

# chmod +x airgap-zarf.sh

#export REGISTRY1_TOKEN=eNjN8fBCh
#export REGISTRY1_USERNAME=Daniel_Toomey

ZARF_LOG_LEVEL=${ZARF_LOG_LEVEL:=debug}

function make_sure_registry1_creds() {
    if [[ -z "${REGISTRY1_USERNAME}" ]]; then
      echo "REGISTRY1_USERNAME is either unset or empty."
      exit 1
    fi
  if [[ -z "${REGISTRY1_TOKEN}" ]]; then
    echo "REGISTRY1_TOKEN is either unset or empty."
    exit 1
  fi
}

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
      return
  fi
  echo "Kubectl is not installed"
  exit 1
}

function zarf_init() {
  if [ ! -f "zarf" ]; then
    ZARF_VERSION=$(curl -sIX HEAD https://github.com/zarf-dev/zarf/releases/latest | grep -i ^location: | grep -Eo 'v[0-9]+.[0-9]+.[0-9]+')
    curl -sL "https://github.com/zarf-dev/zarf/releases/download/${ZARF_VERSION}/zarf_${ZARF_VERSION}_Linux_amd64" -o zarf
    chmod +x zarf
    sudo mv zarf /usr/local/bin/zarf
  fi
  zarf init --components=git-server --confirm --log-level=${ZARF_LOG_LEVEL}
  if [ $? -ne 0 ]; then
      echo "zarf init failed.  Re-running zarf init"
      zarf init --components=git-server
      if [ $? -ne 0 ]; then
        echo "Re-running zarf init failed."
        exit 1
      fi
  fi
}

function docker_login() {
  DOCKER_USERNAME="${REGISTRY1_USERNAME}"
  DOCKER_PASSWORD="${REGISTRY1_TOKEN}"
  DOCKER_REGISTRY="registry1.dso.mil"
  # Perform the Docker login using --password-stdin
  set +o history && echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin "$DOCKER_REGISTRY" || set -o history
  if [ $? -eq 0 ]; then
    echo "Docker login successful."
  else
    echo "Docker login failed."
    exit 1
  fi
}

function create_zarf_package() {
  # create the zst file, zarf-package-bigbang-amd64.tar.zst
  # the filename is built from aspects of the credentials file
  zarf package create . --confirm --log-level=${ZARF_LOG_LEVEL}
  if [ $? -eq 0 ]; then
    echo "zarf package create succeeded."
  else
    echo "zarf package create failed."
    exit 1
  fi
}

function inspect_zarf_package() {
  # make sure it worked - inspect the definition portion of the file
  zarf package inspect definition zarf-package-bigbang-amd64.tar.zst
  if [ $? -eq 0 ]; then
    echo "zarf package inspection succeeded."
  else
    echo "zarf package inspection failed."
    exit 1
  fi
}

function deploy_zarf_package() {
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo "amd64 package cannot be deployed on arm64"
    exit 1
  fi
  zarf package deploy zarf-package-bigbang-amd64.tar.zst --confirm --log-level=${ZARF_LOG_LEVEL}
  if [ $? -eq 0 ]; then
    echo "zarf package deploy succeeded."
  else
      echo "zarf package deploy failed."
      exit 1
  fi
}

function close_down() {
  # credentials file we create to invoke zarf
  sudo rm -f bb-zarf-credentials.yaml

  # the zarf package we create with bigbang
  sudo rm -f zarf-package-bigbang-amd64.tar.zst

  zarf destroy --confirm
}

function main() {
  if [ "$#" -ne 0 ]; then
    "$1" $2
  else
    make_sure_registry1_creds
    make_sure_can_write_local_file
    start_docker
    install_kubernetes
    zarf_init
    docker_login
    create_zarf_package
    inspect_zarf_package
    deploy_zarf_package
    #close_down
    echo "AirGap zarf deployment of BigBang complete"
  fi
}

main "$@"


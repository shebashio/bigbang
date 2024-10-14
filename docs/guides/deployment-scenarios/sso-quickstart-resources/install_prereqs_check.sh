#!/usr/bin/env bash
set -euo pipefail

function check() {
  ${*} &> /dev/null \
    && echo "$(hostname) SUCCESS: '${*}' returned non-failure exit code" \
    || echo -e "\033[31m$(hostname) ERROR:   '${*}' returned failure exit code '$?'. Verify installation or attempt re-install.\033[0m"
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

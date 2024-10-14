#!/usr/bin/env bash
set -euo pipefail

function check() {
  ${*} &> /dev/null \
    && echo "SUCCESS: '${*}' returned non-failure exit code" \
    || echo -e "\033[31mERROR:   '${*}' returned failure exit code. Verify installation or attempt re-install.\033[0m"
}

check_inputs=(
  'docker ps'
  'k3d version'
  'kubectl version'
  'kustomize version'
  'helm version'
)

for i in "${check_inputs[@]}"; do
  check "$i"
done

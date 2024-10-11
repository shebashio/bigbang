/usr/bin/env bash
set -euo pipefail

# Verify install was successful
docker ps >> /dev/null ; echo \$? | grep 0 >> /dev/null && echo "SUCCESS: docker installed" || echo "ERROR: issue with docker install"
k3d version >> /dev/null ; echo \$? | grep 0 >> /dev/null && echo "SUCCESS: k3d installed" || echo "ERROR: issue with k3d install"
kubectl version --client >> /dev/null ; echo \$? | grep 0 >> /dev/null && echo "SUCCESS: kubectl installed" || echo "ERROR: issue with kubectl install"
kustomize version >> /dev/null ; echo \$? | grep 0 >> /dev/null && echo "SUCCESS: kustomize installed" || echo "ERROR: issue with kustomize install"
helm version >> /dev/null ; echo \$? | grep 0 >> /dev/null && echo "SUCCESS: helm installed" || echo "ERROR: issue with helm install"
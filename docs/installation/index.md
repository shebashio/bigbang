# Installation

This section provides guidance for installing Big Bang in different environments. Use it as an entry point for choosing the right deployment path, preparing prerequisites, and understanding the GitOps bootstrap flow.

## Choose a Deployment Path

- **[Quick Start Demo](environments/quick-start.md)**: Use this path for a hands-on demo deployment in a development environment.
- **[Customer Template](https://repo1.dso.mil/big-bang/customers/template)**: Use this repository as the starting point for a real Big Bang environment.
- **[Air-Gapped Deployment](environments/airgap.md)**: Use this guidance for disconnected environments that need mirrored repositories and image registries.
- **[Air-Gapped Deployment with Zarf](environments/airgap-zarf.md)**: Use this path when Zarf is part of your disconnected deployment workflow.
- **[Appliance Mode](environments/appliance-mode.md)**: Review this guidance for constrained or edge-style deployments.
- **[Extra Package Deployment](environments/extra-package-deployment.md)**: Deploy packages outside the standard Big Bang package set.
- **[SSO Quick Start](environments/sso-quickstart.md)**: Add SSO protection to applications with Keycloak and Authservice.

Air-gapped and edge deployments are environment-specific. Review the linked guides carefully and validate them against your target architecture before using them in production.

## Installation Overview

Big Bang uses GitOps principles with Flux to deploy and manage Kubernetes applications. The installation process typically includes:

1. **Cluster preparation:** Ensure your Kubernetes cluster meets Big Bang requirements.
2. **Flux installation:** Install the GitOps engine that manages Big Bang resources.
3. **Big Bang bootstrap:** Apply the customer-template bootstrap resource for your environment.
4. **Package configuration:** Customize enabled packages through values files stored in Git.
5. **Validation:** Verify Flux resources and package workloads converge successfully.

## Prerequisites

Before installing Big Bang, ensure your environment has:

- A supported Kubernetes version. See `kubeVersion` in [Chart.yaml](../../chart/Chart.yaml) and the [prerequisites guide](../getting-started/prerequisites.md).
- Sufficient CPU, memory, and storage for the packages you plan to enable.
- Network access to required Git repositories and registries, or mirrored equivalents for disconnected environments.
- A default `StorageClass` with dynamic volume provisioning.
- A load-balancer or ingress strategy appropriate for your environment.
- Registry1 credentials with a valid image pull token.

## Bootstrap Flow

The exact deployment process varies by scenario. The [Quick Start Demo](environments/quick-start.md) automates several steps using reusable demo configuration. Production deployments should start from the [Big Bang customer template](https://repo1.dso.mil/big-bang/customers/template).

### 1. Obtain Registry1 Credentials

Big Bang container images are sourced from Iron Bank through `registry1.dso.mil`. A Registry1 account with a valid image pull token is required before Big Bang-managed workloads can run, including Flux. You can request robot credentials through the [Iron Bank robot account request form](https://repo1.dso.mil/dsop/big-bang/base/-/work_items/new?initialCreationContext=list-route&type=ISSUE&description_template=Robot%20Account).

Use robot credentials for production deployments rather than personal tokens.

### 2. Prepare Your Git Repository

Big Bang desired state is declared in Git. Before bootstrapping:

- Provision a Git repository that the cluster can reach.
- Commit Big Bang values files configured for your environment, including DNS names, TLS certificates, enabled packages, and registry credentials.
- Encrypt secrets with [SOPS](https://github.com/getsops/sops) or your approved secret-management workflow before committing them.
- Use the [customer template](https://repo1.dso.mil/big-bang/customers/template) as the reference repository structure.

### 3. Install Flux

Install Flux using the bootstrap manifests that match the Big Bang release you are deploying. Pin the release explicitly instead of using `master` in production.

```shell
export REGISTRY1_USER='your-registry1-username'
export REGISTRY1_TOKEN='your-registry1-token'
export BB_VERSION='<target-bigbang-version>'

kubectl create namespace flux-system

kubectl create secret docker-registry private-registry \
  --docker-server=registry1.dso.mil \
  --docker-username="${REGISTRY1_USER}" \
  --docker-password="${REGISTRY1_TOKEN}" \
  --namespace flux-system

kubectl apply -k "https://repo1.dso.mil/big-bang/bigbang.git//base/flux?ref=${BB_VERSION}"
```

Alternatively, use the install script included in the Big Bang repository:

```shell
git clone https://repo1.dso.mil/big-bang/bigbang.git
./bigbang/scripts/install_flux.sh -u "${REGISTRY1_USER}" -p "${REGISTRY1_TOKEN}"
```

Verify Flux is running before proceeding:

```shell
kubectl get pods -n flux-system
kubectl get crds | grep flux
```

### 4. Deploy Big Bang

With Flux running and your Git repository configured, apply the bootstrap resource from your customer-template repository:

```shell
kubectl apply --filename bigbang.yaml
```

A reference `bigbang.yaml` is available in the [customer template](https://repo1.dso.mil/big-bang/customers/template/-/blob/main/helmRepo/dev/bigbang.yaml).

This triggers the GitOps bootstrap flow:

1. `bigbang.yaml` creates Flux `GitRepository` and `Kustomization` resources.
2. Flux reconciles the `Kustomization` and applies the environment manifests from Git.
3. The environment manifests create a `HelmRelease` for the Big Bang Helm chart.
4. The Big Bang Helm chart creates package `GitRepository`, `HelmRepository`, and `HelmRelease` resources for enabled packages.
5. Flux reconciles each enabled package independently.

### 5. Validate

Monitor the rollout until all resources converge:

```shell
watch kubectl get gitrepositories,kustomizations,helmreleases,pods -A
kubectl get pods -A | grep -Ev 'Running|Completed'
```

All `HelmRelease` resources should reach `Ready: True`. Packages may take several minutes to reconcile depending on cluster resources and image pull times.

## When Installation Problems Occur

Installation issues can occur at different stages of the deployment process. Use the [troubleshooting documentation](../operations/troubleshooting/) to identify failures by symptom and deployment stage.

Start with:

1. **Installation troubleshooting** for immediate deployment failures.
2. **Package troubleshooting** for individual component issues.
3. **Networking troubleshooting** for connectivity and ingress issues.
4. **Performance troubleshooting** for resource-related issues.

## Post-Installation Operations

After a successful installation, review:

- [Monitoring](../operations/monitoring.md)
- [Backup and Restore](../operations/backup-restore.md)
- [Upgrades](../operations/upgrades.md)
- [Maintenance](../operations/maintenance/)

## Getting Help

If troubleshooting guides do not resolve your issue:

- Gather diagnostic information using commands from the troubleshooting guides.
- Check the Big Bang GitLab repository for similar reported issues.
- Engage with the Big Bang community with a clear problem description and relevant logs.
- Escalate through your platform support path with collected diagnostic data.

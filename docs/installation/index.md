# Installation

This section provides guidance for installing Big Bang in various environments. Whether you're setting up a new cluster or migrating from an existing deployment, these documents will guide you through the installation process and help you avoid common pitfalls.

## What You'll Find Here

The installation documentation covers the essential aspects of deploying Big Bang:

- **Prerequisites**: Cluster requirements, infrastructure setup, and dependency verification
- **Installation Methods**: Step-by-step installation procedures for different environments
- **Configuration**: Essential configuration options and customization guidance
- **Validation**: Post-installation verification and health checks

## Installation Overview

Big Bang uses GitOps principles with Flux to deploy and manage Kubernetes applications. The installation process typically involves:

1. **Cluster Preparation**: Ensuring your Kubernetes cluster meets Big Bang requirements
2. **Flux Installation**: Setting up the GitOps engine that manages deployments
3. **Big Bang Deployment**: Configuring and deploying the Big Bang umbrella chart
4. **Package Configuration**: Customizing individual packages for your environment
5. **Validation**: Verifying successful deployment and functionality

## Quick Start

For a basic installation:

1. Verify cluster meets [prerequisites](#prerequisites)
2. Install Flux controllers
3. Deploy Big Bang with your configuration
4. Validate installation using the health checks

## Prerequisites

Before installing Big Bang, ensure your environment meets these requirements:

- **Kubernetes Version**: Compatible Kubernetes cluster (see compatibility matrix)
- **Node Resources**: Sufficient CPU, memory, and storage capacity
- **Network Access**: Connectivity to required registries and repositories
- **Storage Classes**: Available persistent storage for applications
- **Load Balancer**: External load balancer capability (cloud or on-premises)

See the [detailed prerequisites guide](../getting-started/prerequisites.md) for more information.

## Common Installation Scenarios

Big Bang supports various deployment patterns:

- **Cloud Deployments**: AWS EKS, Azure AKS, Google GKE
- **On-Premises**: Self-managed Kubernetes clusters
- **Edge Deployments**: Resource-constrained environments
- **Air-Gapped**: Disconnected environments with registry mirrors

## How do I deploy Big Bang?

**Note:** The Deployment Process and Pre-Requisites will vary depending on the deployment scenario. The [Quick Start Demo Deployment](../installation/environments/quick-start.md) for example, allows some steps to be skipped due to a mixture of automation and generically reusable demonstration configuration that satisfies pre-requisites. The following is a general overview of the process, reference the [deployment guides](../installation/index.md) for more detail.

1. Satisfy Pre-Requisites:
    * Provision a Kubernetes Cluster according to [best practices](./prerequisites.md#kubernetes-cluster).
    * Ensure the cluster has network connectivity to a Git Repo you control.
    * Install Flux GitOps Operator on the cluster.
    * Configure Flux, the cluster, and the Git Repo for GitOps Deployments that support deploying encrypted values.
    * Commit to the Git Repo Big Bang's `values.yaml` and encrypted secrets that have been configured to match the desired state of the cluster (including HTTPS Certs and DNS names).
1. `kubectl apply --filename bigbang.yaml`
    * [bigbang.yaml](https://repo1.dso.mil/big-bang/customers/template/-/blob/main/helmRepo/dev/bigbang.yaml) will trigger a chain reaction of GitOps Custom Resources that will deploy other GitOps Custom Resources that will eventually deploy an instance of a DevSecOps Platform that's declaratively defined in your Git Repo.
    * To be specific, the chain reaction pattern we consider best practice is to have:
        * `bigbang.yaml` deploys a git repository and kustomization Custom Resource.
        * Flux reads the declarative configuration stored in the kustomization Custom Resource to do a GitOps equivalent of `kustomize build . | kubectl apply  --filename -`, to deploy a helmrelease Custom Resource of the Big Bang Helm Chart, that references input `values.yaml` files defined in the Git Repo.
        * Flux reads the declarative configuration stored in the helmrelease Custom Resource to do a GitOps equivalent of `helm upgrade --install bigbang /chart  --namespace=bigbang  --filename encrypted_values.yaml --filename values.yaml --create-namespace=true`, the Big Bang Helm Chart, then deploys more Custom Resources that flux uses to deploy packages specified in Big Bang's `values.yaml.`

## New User Orientation

New users are encouraged to read through the useful background information present in the [Getting Started](../getting-started/), [Concepts](../concepts/), [Configuration](../configuration/), and [Packages](../packages/) sections.


## When Installation Problems Occur

Installation issues can manifest at different stages of the deployment process. Our [troubleshooting documentation](../operations/troubleshooting/index.md) is organized to help you quickly identify and resolve problems based on the symptoms you're experiencing:

### Diagnostic Approach

When facing installation problems, follow this systematic approach:

1. **Start with Installation Troubleshooting** for immediate deployment failures
2. **Move to Package Troubleshooting** for individual component issues
3. **Check Networking Troubleshooting** for connectivity problems
4. **Use Performance Troubleshooting** for resource-related issues

Each guide provides both quick diagnostic commands and detailed remediation steps, allowing you to either quickly resolve common issues or dive deep into complex problems.

## Post-Installation Operations

After successful installation, transition to operational procedures:

1. **Set Up Monitoring**: Configure observability using [Operations Monitoring](../operations/monitoring.md)
2. **Plan Backups**: Implement backup strategies from [Operations Backup & Restore](../operations/backup-restore.md)
3. **Review Upgrades**: Understand upgrade procedures in [Operations Upgrades](../operations/upgrades.md)
4. **Ongoing Maintenance**: Follow guidance in [Operations Maintenance](../operations/maintenance/)

## Getting Help

If troubleshooting guides don't resolve your issue:

- Gather diagnostic information using commands from the troubleshooting guides
- Check Big Bang GitLab repository for similar reported issues
- Engage with the Big Bang community with detailed problem descriptions
- Consider escalating to platform support with collected diagnostic data

The troubleshooting documentation is designed to provide both immediate solutions and the diagnostic information needed for effective support requests.

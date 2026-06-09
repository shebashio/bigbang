# What is Big Bang?

Big Bang is an umbrella Helm chart for deploying and managing a DevSecOps platform on Kubernetes using GitOps workflows. The platform is composed of open-source and commercial application packages, bundled as Helm charts, that use hardened container images from Iron Bank.

At a high level, Big Bang provides:

- A curated set of integrated packages for security, observability, policy enforcement, and software delivery.
- Hardened images sourced from Iron Bank.
- GitOps-based lifecycle management using Flux.
- Standardized package integration patterns for Kubernetes platform teams.

### How Big Bang Works

Big Bang follows a declarative workflow:

1. You define desired state in Git, including values files, manifests, and overlays.
2. Flux reconciles that state into your cluster.
3. Big Bang deploys and configures package integrations through Helm.

In practice, the Big Bang Helm chart installs and manages resources such as `GitRepository`, `HelmRepository`, and `HelmRelease` custom resources that Flux continuously reconciles.

You can inspect reconciled resources with:

```shell
kubectl get gitrepositories,helmreleases -A
```

### What Is Included

Big Bang includes platform capabilities across several categories:

- **Security and policy enforcement:** Big Bang supports defense-in-depth and Zero Trust-oriented architectures with policy enforcement, workload controls, and hardened images.
- **Service mesh and traffic security:** Big Bang uses Istio service mesh capabilities for secure service-to-service communication, mTLS, traffic policy, and workload identity controls.
- **Observability and alerting:** Big Bang provides monitoring, logging, tracing, dashboards, and alerting through integrated observability packages.
- **Software delivery integrations:** Big Bang integrates with tools such as GitLab, Argo CD, Harbor, SonarQube, and Fortify when those packages are enabled.
- **Operations and lifecycle tooling:** Big Bang includes operational workflows for upgrades, policy validation, observability, backup and restore, and ongoing package maintenance.

For current package coverage and versions, see:

- [Packages](packages/) lists package documentation by category.
- [Release Notes](https://repo1.dso.mil/big-bang/bigbang/-/releases) list packages and versions for each Big Bang release.
- [Big Bang's default values.yaml](../chart/values.yaml) is the code-based source of truth for package defaults and versions.
- [Big Bang Universe](https://universe.bigbang.dso.mil) provides an interactive visual of Core, Add-on, and Community packages as described in the [Big Bang README](../README.md#usage--scope).

## What isn't Big Bang?

Big Bang by itself is not an end-to-end secure Kubernetes cluster solution. It is one major component of a broader platform architecture that also includes cluster hardening, identity, networking, ingress protection, operational processes, and mission-application security.

A complete secure Kubernetes platform usually has multiple components. Some are swappable, and some may be optional depending on the use case and risk tolerance.

Examples of components in a full solution include:

- **Ingress traffic protection:** Platform One's Cloud Native Access Point (CNAP) is one solution, but deployments may use an equivalent solution or omit this layer in some disconnected environments.
- **Hardened host operating system:** Big Bang does not harden the host OS.
- **Hardened Kubernetes cluster:** Big Bang assumes bring your own cluster (BYOC). Consumers should work with Kubernetes distribution vendors or platform providers to meet cluster hardening requirements.
- **Hardened mission applications:** Iron Bank hardened containers help address this need, and Big Bang uses Iron Bank images for Big Bang-managed packages.

This scope boundary helps teams adopt Big Bang as a reusable platform layer while retaining flexibility for environment-specific architecture decisions.

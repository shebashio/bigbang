# What is Big Bang?

Big Bang is an umbrella Helm chart for deploying and managing a secure DevSecOps platform on Kubernetes using GitOps workflows. The DevSecOps Platform is composed of application packages of open-source and commercial software, which are bundled as helm charts that leverage Iron Bank hardened container images. It leverages Flux CD for GitOps-based deployments and provides several key features to increase the improve the deployment and maintenance experience of cloud-native applications. 
The Big Bang Helm Chart deploys gitrepository and helmrelease Custom Resources to a Kubernetes Cluster running the Flux GitOps Operator, these can be seen using `kubectl get gitrepository,helmrelease -n=bigbang.` Flux then installs the helm charts defined by the Custom Resources into the cluster.
At a high level, Big Bang provides the following:
* A curated set of integrated packages for security, observability, policy enforcement, and software delivery
* Hardened images sourced from Iron Bank
* GitOps-based lifecycle management using Flux

### How Big Bang Works
Big Bang follows the declarative workflow defined below:
1.	You define desired state in Git (values.yaml, manifests, and overlays).
2.	Flux reconciles that state into your cluster.
3.	Big Bang deploys and configures package integrations through Helm.

In practice, this means Big Bang installs and manages resources such as GitRepository, HelmRepository, and HelmRelease custom resources that Flux continuously reconciles.

You can inspect reconciled resources with:

`kubectl get gitrepositories,helmreleases -A`

### What Is Included
Big Bang includes platform capabilities across several categories:
* **Security and policy enforcement:** Big Bang adheres to Zero Trust Security, providing an architecture with access limited to only the minimum amount of permissions that users need to perform their duties effectively.  In order to achieve maximum Zero Trust adherence, we offer built-in security controls with defense-in-depth architecture.
* **Service mesh and traffic security:** Istio-based secure service-to-service communication
* **Observability and alerting:** Monitoring, logging, and tracing are key components to accomplishing both Zero Trust Architecture, and best-practice design for our platform. Big Bang provides a high-level of observability by offering comprehensive monitoring, logging, and tracing capabilities.
* **Software factory and delivery integrations:**
* **Operations and lifecycle tooling:**

For current package coverage and versions, see:
* [packages.md](../packages/index.md) lists the packages and organizes them in categories.
* [Release Notes](https://repo1.dso.mil/big-bang/bigbang/-/releases) lists the packages and their versions.
* For a code based source of truth, you can check [Big Bang's default values.yaml](../../chart/values.yaml), and `[CTRL] + [F]`, `"repo:"`, to quickly iterate through the list of applications supported by the Big Bang team.
* [Big Bang Universe](https://universe.bigbang.dso.mil) provides an interactive visual of all packages in Core, Addons, and Community as described in [Big Bang README](../../README.md#usage--scope)


## What isn't Big Bang?

Big Bang by itself is not intended to be an End-to-End Secure Kubernetes Cluster Solution, but rather, Big Bang is one major component of a broader platform architecture that also includes cluster hardening, identity, networking, and operational processes.

A Secure Kubernetes Cluster Solution will have multiple components that can each be swappable and in some cases considered optional depending on use case and risk tolerance.

Some example of potential components in a full end-to-end solution include:
* Ingress traffic protection
  * Platform One's Cloud Native Access Point (CNAP) is one solution.
  * CNAP can be swapped with an equivalent, or considered optional in an internet disconnected setup.
* Hardened Host OS
* Hardened Kubernetes Cluster
    * Big Bang does not provision your Kubernetes cluster, but instead assumes Bring your own Cluster (BYOC)
    * The Big Bang team recommends consumers who are interested in a full solution, partner with Vendors of Kubernetes Distributions to satisfy the prerequisite of a Hardened Kubernetes Cluster.
* Hardened Applications running on the Cluster
    * Iron Bank provides hardened containers that helps solve this component.
    * Big Bang utilizes the hardened containers in Iron Bank.

This scope boundary helps teams adopt Big Bang as a reusable platform layer while retaining flexibility for environment-specific architecture decisions.
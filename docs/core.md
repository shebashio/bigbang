# Core Capabilities
**[Again, we want a high-level description here. Something like: "The core capabilities of big bang fall into three categories: Security and Compliance features that provide easy-to-manage protection, monitoring, and incident response through, as well as management tools to maintain consistency; Observability capabilities that provide dashboard visibility into metrics, distribution, and alerts; and Developer tools, which provides four main tools to help for application deployment. artifact management, quality analysis, and code management.]**

### Usage & Scope

Big Bang's scope is to provide publicly available installation manifests for packages required to adhere to the DoD DevSecOps Reference Architecture and additional useful utilities. Big Bang packages are broken into three categories:

- **Core:** [Core packages](./docs/packages/index.md#core) are a group of capabilities required by the DoD DevSecOps Reference Architecture, that are supported directly by the Big Bang development team. The specific capabilities that are considered core currently are Service Mesh, Policy Enforcement, Logging, Monitoring, and Runtime Security.

- **Add-ons:** [Addon packages](./docs/packages/index.md#supported-add-ons) are any packages/capabilities that the Big Bang development team directly supports that do not fall under the above core definition. These serve to extend the functionality/features of Big Bang.

- **Community:** [Community packages](https://repo1.dso.mil/big-bang/product/community) are any packages that are maintained by the broader Big Bang community (e.g., users and/or vendors). These packages could be alternatives to core or add-on packages, or even entirely new packages to help extend usage/functionality of Big Bang.



### Security and Compliance
- Istio service mesh with mutual TLS
- Kyverno policy engine for admission control
- Runtime security with vulnerability scanning
- Supply chain security with image signing

### Observability
- Prometheus and Grafana for metrics and dashboards
- Elasticsearch and Kibana for log aggregation and analysis
- Tempo for distributed tracing
- Alertmanager for notification management

### Developer Tools
- GitLab for source code management and CI/CD
- ArgoCD for application deployment and management
- Nexus for artifact and dependency management
- SonarQube for code quality and security analysis

### Packages
Big Bang's scope is to provide publicly available installation manifests for packages required to adhere to the DoD DevSecOps Reference Architecture and additional useful utilities. Big Bang packages are broken into three categories:

Understand and configure Big Bang components:
- **[Package Index](packages/)**: Complete list of available packages
- **[Core Packages](packages/core/)**: A group of capabilities required by the DoD DevSecOps Reference Architecture, that are supported directly by the Big Bang development team. The specific capabilities that are considered core currently are Service Mesh, Policy Enforcement, Logging, Monitoring, and Runtime Security.
- **[Add-on Packages](packages/addons/)**: Any packages/capabilities that the Big Bang development team directly supports that do not fall under the above core definition. These serve to extend the functionality/features of Big Bang.
- **[Community Packages](https://repo1.dso.mil/big-bang/product/community)**: Any packages that are maintained by the broader Big Bang community (e.g., users and/or vendors). These packages could be alternatives to core or add-on packages, or even entirely new packages to help extend usage/functionality of Big Bang.

In order for an installation of Big Bang to be a valid installation/configuration, you must install/deploy a core package of each category. For additional details on categories and options, see [here](./docs/packages/index.md#core).

Big Bang also builds tooling around the testing and validation of Big Bang packages. These tools are provided as-is, without support.

Big Bang is intended to be used for deploying and maintaining a DoD hardened and approved set of packages into a Kubernetes cluster.  Deployment and configuration of ingress/egress, load balancing, policy auditing, logging, and/or monitoring are handled via Big Bang.  Additional packages (e.g., ArgoCD and GitLab) can also be enabled and customized to extend Big Bang's baseline.  Once deployed, the Kubernetes cluster can be used to add mission specific applications.


### Core Concepts
Understand Big Bang's architecture and design:
- **[Architecture](concepts/architecture.md)**: System design and component relationships
- **[Security Model](concepts/security-model.md)**: Zero trust security implementation
- **[GitOps Workflow](concepts/git-ops-workflow.md)**: Deployment and management patterns
- **[Package Management](concepts/package-management.md)**: Managing Big Bang components

### Operations
Day-to-day management and maintenance:
- **[Operations](operations/)**: Monitoring, backup, and maintenance procedures
- **[Troubleshooting](operations/troubleshooting/)**: Diagnose and resolve common issues
- **[Upgrades](operations/upgrades.md)**: Version management and upgrade procedures

# Big Bang Capabilities

Big Bang capabilities fall into six product areas: architecture, security and compliance, observability, software delivery, operations, and package management.

### Architecture

The [architecture overview](concepts/architecture.md) includes diagrams for the following data flows:

- Kubernetes API server webhooks
- Logs data
- Metrics data
- Network encryption and ingress

### Security and Compliance

Big Bang has the following features to support security and compliance:

- Istio service mesh with mutual TLS
- Kyverno policy engine for admission control
- Runtime security with vulnerability scanning
- Supply chain security with image signing

See the [security model](concepts/security-model.md) for more information.

### Observability

Big Bang includes features that increase operational visibility:

- Prometheus and Grafana for metrics and dashboards
- Grafana Alloy and Loki for log collection and aggregation
- Tempo for distributed tracing
- Alertmanager for notification management
- Optional Elasticsearch and Kibana support for environments that use the ECK-based logging stack

### Software Delivery Tools

Big Bang can enable the following packages to support software delivery workflows:

- GitLab for source code management and CI/CD
- Argo CD for application deployment and management
- Harbor for container registry workflows
- SonarQube for code quality and security analysis
- Fortify for security scanning

For more information, see the [GitOps workflow](concepts/git-ops-workflow.md).

### Operations

The following links provide more information on the day-to-day management and maintenance of Big Bang:

- **[Operations](operations/)**: Monitoring, backup, and maintenance procedures
- **[Troubleshooting](operations/troubleshooting/)**: Diagnose and resolve common issues
- **[Upgrades](operations/upgrades.md)**: Version management and upgrade procedures

### Packages

Big Bang's scope is to provide publicly available installation manifests for packages required to adhere to the DoD DevSecOps Reference Architecture and additional useful utilities. Big Bang packages are broken into three categories:

- **[Core Packages](packages/core/)**: A group of capabilities required by the DoD DevSecOps Reference Architecture, that are supported directly by the Big Bang development team. The specific capabilities that are considered core currently are Service Mesh, Policy Enforcement, Logging, Monitoring, and Runtime Security.
- **[Add-on Packages](packages/addons/)**: Any packages/capabilities that the Big Bang development team directly supports that do not fall under the above core definition. These serve to extend the functionality/features of Big Bang.
- **[Community Packages](https://repo1.dso.mil/big-bang/product/community)**: Any packages that are maintained by the broader Big Bang community (e.g., users and/or vendors). These packages could be alternatives to core or add-on packages, or even entirely new packages to help extend usage/functionality of Big Bang.

See [Packages](packages/) for a complete list of available packages.

In order for an installation of Big Bang to be a valid installation/configuration, you must install/deploy a core package of each category.

Big Bang also builds tooling around the testing and validation of Big Bang packages. These tools are provided as-is, without support.

Big Bang is intended to deploy and maintain a DoD hardened and approved set of packages into a Kubernetes cluster. Deployment and configuration of ingress and egress, load balancing, policy auditing, logging, and monitoring are handled through Big Bang package integrations. Additional packages such as Argo CD and GitLab can also be enabled and customized to extend Big Bang's baseline. Once deployed, the Kubernetes cluster can be used to add mission-specific applications.

See [Package Management](concepts/package-management.md) for more information about Big Bang package management.

# Core Capabilities
**[Again, we want a high-level description here. Something like: "The core capabilities of big bang fall into three categories: Security and Compliance features that provide easy-to-manage protection, monitoring, and incident response through, as well as management tools to maintain consistency; Observability capabilities that provide dashboard visibility into metrics, distribution, and alerts; and Developer tools, which provides four main tools to help for application deployment. artifact management, quality analysis, and code management.]**
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
Understand and configure Big Bang components:
- **[Package Index](packages/)**: Complete list of available packages
- **[Core Packages](packages/core/)**: Essential infrastructure components
- **[Add-on Packages](packages/addons/)**: Optional application packages

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

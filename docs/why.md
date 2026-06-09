# Why Use Big Bang?

Big Bang helps platform teams deploy and maintain a secure DevSecOps platform with reusable GitOps workflows, hardened images, and integrated Kubernetes packages. It reduces the amount of platform integration work teams must perform before they can focus on mission applications.

## What are the benefits of using Big Bang?

Big Bang provides the following key benefits to users:

- **Reference architecture alignment:** Big Bang supports implementation patterns aligned with the [DoD DevSecOps Reference Architecture Design](https://dodcio.defense.gov/Portals/0/Documents/Library/DoD%20Enterprise%20DevSecOps%20Reference%20Design%20-%20CNCF%20Kubernetes%20w-DD1910_cleared_20211022.pdf).
- **ATO and cATO support:** Big Bang can reduce the compliance burden by providing hardened, reusable platform components and documentation that teams can use as part of their authorization evidence. Final control inheritance and authorization decisions remain environment-specific.
- **Supply-chain security:** Big Bang shifts supply-chain concerns earlier by using hardened Iron Bank container images for Big Bang-managed packages.
- **GitOps control:** Big Bang uses GitOps to keep desired state in Git, produce an audit trail, and reduce configuration drift caused by out-of-band cluster changes.
- **Lower maintenance overhead:** Platform teams can update a Big Bang release reference and allow Flux to reconcile package updates through the umbrella Helm chart pattern.
- **SSO support:** Big Bang can deploy and integrate SSO-related packages such as Keycloak and Authservice. For package integration details, see the [SSO integration guide](community/development/package-integration/sso.md).

> **Note:** Big Bang supports and tests successive upgrades. Skipping minor versions is not supported and may result in broken deployments.

> **Note:** While Flux supports wildcard versioning such as `1.x.x`, this is not recommended for production environments. Automatic version advancement bypasses change control processes. Pin to an explicit version in production and upgrade deliberately.

## Team Benefits

Big Bang provides different benefits depending on the teams using it.

### For Platform Teams

- **Faster platform setup:** Deploy an integrated Kubernetes platform using tested package integrations.
- **Security-focused defaults:** Use built-in service mesh, policy enforcement, hardened images, and GitOps workflows.
- **Operational visibility:** Use integrated observability packages such as Prometheus, Grafana, Grafana Alloy, Loki, and Tempo.
- **Standardization:** Reduce cluster drift by managing environments through declared Git state.

### For Development Teams

- **Focus on applications:** Consume platform capabilities without owning every infrastructure integration.
- **Modern toolchain:** Use enabled packages such as GitLab, Argo CD, SonarQube, Fortify, and Harbor.
- **Security integration:** Build on platform controls for ingress, service mesh, logging, policy enforcement, and SSO.
- **Self-service workflows:** Deploy through GitOps patterns with less direct cluster access.

### For Organizations

- **Compliance support:** Build on platform controls that support NIST, FedRAMP, and DoD security objectives.
- **Cost efficiency:** Reduce repeated platform integration and maintenance work across teams.
- **Risk reduction:** Use hardened images, tested integrations, and Git-managed desired state to reduce avoidable platform risk.
- **Vendor flexibility:** Use an open-source foundation with support options across the broader ecosystem.

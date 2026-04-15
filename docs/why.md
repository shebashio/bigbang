# Why Use Big Bang?
**[Include here some high-level description of the value gained from using Big Bang. What are the problems or risks we are addressing? Why is it necessary? In broad terms, as opposed to the specific ones down below. Also, the list below really just seems like a list of features. That's not really an answer to "why?" Like why is Big Bang useful to a platform team? Why are these features of particular importance?]**
## What are the benefits of using Big Bang?
**[Copied here from the getting started page in order to build out these subpages]**

Big Bang provides the following key benefits to users:
* Compliant with the [DoD DevSecOps Reference Architecture Design](https://dodcio.defense.gov/Portals/0/Documents/Library/DoD%20Enterprise%20DevSecOps%20Reference%20Design%20-%20CNCF%20Kubernetes%20w-DD1910_cleared_20211022.pdf).
* Can be used to check some but not all of the boxes needed to achieve a Continuous Authority to Operate (cATO) or Authority to Operate (ATO).
* Left shift supply chain security concerns using hardened Iron Bank container images.
* GitOps adds security benefits, and Big Bang leverages GitOps, and can be further extended using GitOps.
  Security Benefits of GitOps:
  * Prevents configuration drift between state of a live cluster and IaC/CaC source of truth: By avoiding giving any humans direct `kubectl` access, by only allowing humans to deploy via git commits, out of band changes are limited.
  * Git Repo based deployments create an audit trail.
  * Reusable secure configurations lowers the burden of implementing secure configurations.
* Lowers maintainability overhead involved in keeping the images of a DevSecOps Platform up to date and maintaining a secure posture over the long term. This is achieved by pairing the GitOps pattern with the Umbrella Helm Chart Pattern.
  Let's walk through an example:
  * Initially a `kustomization.yaml` file in a git repo will tell the Flux GitOps operator (software deployment bot running in the cluster), to deploy version 1.0.0 of Big Bang. Big Bang could deploy 10 helm charts and each helm chart could deploy 10 images. (In this example, Big Bang is managing 100 container images.)
  * After a two-week sprint, version 1.1.0 of Big Bang is released. A Big Bang consumer updates the `kustomization.yaml` file in their git repo to point to version 1.1.0 of the Big Bang Helm Chart. That triggers an update of 10 helm charts to a new version of the helm chart. Each updated helm chart will point to newer versions of the container images managed by the helm chart.
  * When the end user edits the version of one `kustomization.yaml` file, that triggers a chain reaction that updates 100 container images in the cluster.
  * These upgrades are pre-tested. The Big Bang team "eats our own dogfood." Our CI jobs for developing the Big Bang product, run against a Big Bang Dogfood Cluster, and as part of our release process we upgrade our Big Bang Dogfood Cluster, before publishing each release.
  > **Note:** We ONLY support and recommend successive upgrades. We do not test upgrades that skip multiple minor versions.
  * Auto updates are also possible by setting kustomization.yaml to 1.x.x, because Big Bang follows semantic versioning per the [Big Bang README](../../README.md#release-schedule), and flux is smart enough to read x as the most recent version number.
* SSO support is included in the Big Bang platform offering. Operations teams can leverage Big Bang's free Single Sign On capability by deploying the [Keycloak project](https://www.keycloak.org/). Using Keycloak, an ops team configures the platform SSO settings so that SSO can be leveraged by all apps hosted on the platform. For details, see the [SSO Readme](../community/development/package-integration/sso.md). Once Authservice is configured, to enable SSO for an individual app, developers need only ensure the presence of the two following labels:
  - __Namespace__ `istio-injection=enabled`: transparently injects mTLS service mesh protection into their application's Kubernetes YAML manifest
  - __Pod__ `protect=keycloak`: declares an EnvoyFilter CustomResource to auto inject an SSO Authentication Proxy in front of the data path to get to their application

## Team Benefits

Additionally, Big Bang provides a number of benefits depending on the type of team using it, Platform Teams, Development Teams, and Organizations will each find key features that are especially useful to their efforts and concerns.

### For Platform Teams
Since platform teams are tasked with maintaining environments, they need easy-to-use and consistent security. Big Bang provides that by having platform and security be a focus of our out-of-the-box offerings
- **Rapid Platform Setup**: Deploy a production-ready Kubernetes platform in hours, not months
- **Security by Default**: Built-in security controls and compliance frameworks
  **[What type of security controls?]**
- **Operational Excellence**: Integrated monitoring, alerting, and lifecycle management
  **[Can we talk about the way this is integrated or why that's important?]**
- **Standardization**: Consistent platform across environments and teams
  **[As opposed to what? What is the lack of standardization that teams are dealing with that we are solving?]**_

### For Development Teams
**[Again, we can say something here specific to development teams at a high level. Specifically, what is different from a platform team's concerns. Perhaps something like: "With Big Bang, development teams can focus on application development with state-of-the-art tooling without concerning themselves with development operations and platform maintenance. This leads to a more focused and efficient development pipeline."]**
- **Focus on Applications**: Platform capabilities provided out-of-the-box
  **[So earlier, we talked about what this does for platform teams. Are the platform capabilities provided out of the box, or are they just conveniently accessed by platform teams, who can more efficiently manage that platform?]**
- **Modern Toolchain**: Access to industry-leading development and deployment tools
  **[Is it sufficient to say this? Should we give examples?]**
- **Secure by Design**: Security controls integrated into the development workflow
- **Self-Service**: GitOps-driven deployments with minimal operational overhead

### For Organizations
**[Organizations definitely have different concerns that either team, right? And you do address those in the bullets, but we want, again, a high-level answer here. Something like: "For organizations, there is a greater concern about cost, compliance, and risk awareness, Big Bang's features address those concerns in the following ways:"]**
- **Compliance**: Built-in support for NIST, FedRAMP, and DoD security standards
- **Cost Efficiency**: Reduced time-to-market and operational overhead
  **[Is it beneficial here to give a value on that reduction?]**
- **Risk Reduction**: Proven, tested platform components
  **[We want more details here. What risks are they addressing?]**
- **Vendor Independence**: Open-source foundation with commercial support options

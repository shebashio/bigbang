# Frequently Asked Questions

Use this page to understand what Big Bang provides, deploy and configure it, keep it upgraded, and find the right help.

## Find the Right Starting Point

| Your goal | Start here |
| --- | --- |
| Understand whether Big Bang fits your program | [Overview](../index.md), [Architecture](../concepts/architecture.md), and the [Big Bang Universe](https://universe.bigbang.dso.mil/) |
| Prepare a deployment | [Prerequisites](prerequisites.md) |
| Deploy a mission application | [Extra Package Deployment](../installation/environments/extra-package-deployment.md) |
| Upgrade an existing deployment | [Upgrades](../operations/upgrades.md) |
| Report a defect or request a feature | [Big Bang work items](https://repo1.dso.mil/big-bang/bigbang/-/issues) |

## Understand Big Bang

> Why choose Big Bang instead of deploying upstream Helm charts directly?

Big Bang bundles coordinated package versions and built-in integration patterns for GitOps, networking, policy, observability, and security — work you'd otherwise redo for every upstream chart yourself. Deploying upstream charts directly gives you more flexibility, but you own the integration, security configuration, and upgrade coordination. See the [Security Model](../concepts/security-model.md).

A platform team typically owns the cluster and Big Bang configuration; application teams own their own charts. Either way, one team should have clear end-to-end ownership.

## Getting Started

> Will using Big Bang cost anything, do we need a contract, or does a government PM need to submit a formal request first?

No to all three. Big Bang is open-source and free to use — no cost, contract, or permission needed from Platform One. You control which components you install, though your Approving Official may require certain commercial applications for a cATO. See the [Licensing Model](../concepts/licensing.md) for details.

Platform One also offers optional paid services if you want them: the Big Bang Integration Team (install/upgrade/operate support), Digital Twin (tests baseline changes against your app), and [Party Bus](https://p1.dso.mil/partybus) (a fully managed environment — no cluster to operate). [Contact us](https://p1.dso.mil/contact-us) for details, or share feedback through our [Feedback Form](https://forms.osi.apps.mil/r/QjGsAfZLeV).

## Security

> Is Big Bang secure? What about its plugins?

Big Bang provides configurable GitOps, policy, service-mesh, observability, and runtime-security integrations, but security applies to your whole deployed system, not the chart alone. Package selection, hardening, identity, and control evidence remain your responsibility as the system owner. See the [Security Model](../concepts/security-model.md).

Most package images come from [Iron Bank](https://p1.dso.mil/ironbank), but you still need to verify every image your specific configuration renders — scan results don't replace your own vulnerability-management process.

## Deploying and Configuring

> Can we stand up our own instance of Big Bang in AWS GovCloud?

Yes, if your cluster is conformant and meets the selected release's requirements — Big Bang supports GovCloud, other clouds, on-prem, and disconnected environments, but don't assume support based on the provider name alone. Check the exact requirements and test in a non-production cluster first. See [Prerequisites](prerequisites.md).

> Do we have to set up a full Kubernetes distribution, or can we deploy to a VM?

Big Bang is a Helm chart, so it requires a full Kubernetes environment — there's no VM-only path. If your organization can't support Kubernetes, consider [Party Bus](https://p1.dso.mil/partybus) (Platform One's managed PaaS) or a Big Bang Reseller on the [P1 Solutions Marketplace](https://p1.dso.mil/marketplace).

> Can I deploy an application that isn't already a Big Bang package?

Yes, through Big Bang's `packages` configuration. The optional Wrapper chart adds common integrations — Istio, monitoring, network policies, secrets, limited SSO — automatically. You still own the app's chart, images, values, and testing. See [Extra Package Deployment](../installation/environments/extra-package-deployment.md).

> How do I get a new package integrated into Big Bang?

Follow the [package lifecycle onboarding](../community/development/package-lifecycle/onboarding.md), [integration](../community/development/package-lifecycle/integration.md), and [developing a package](../community/development/develop-package.md) guides.

> Can I validate or dry-run my configuration before deployment?

Yes — use `helm template` and `kustomize build` to render and review your config locally. But no local command fully proves it'll work in your cluster: test in a staging environment that mirrors production, since CRDs, admission policies, and other runtime dependencies can only be validated against a real cluster. See [Configuration](../configuration/index.md).

> Can I use cloud-native registry authentication instead of a static image pull secret?

Often, yes — leave `registryCredentials` null in your values if your environment provides ambient pull access, such as an AWS EKS node IAM role with ECR access. Support varies by release, package, and registry, so test before relying on it. This isn't currently documented for Azure/AKS — open a [work item](https://repo1.dso.mil/big-bang/bigbang/-/issues) if you hit issues there.

> Can I use Vault, AWS Secrets Manager, or another external secret store instead of SOPS?

Yes. SOPS is Big Bang's default for Git-committed secrets, but the optional External Secrets Operator package can sync values from AWS Secrets Manager or Vault instead. You'll configure the provider and access policies yourself. See [External Secrets Operator](../packages/addons/external-secrets-operator.md).

## Upgrades and Change Control

> How do you manage change control? How can we be notified of changes?

Big Bang releases every two weeks. See the [release schedule](../index.md#release-schedule), [project milestones](https://repo1.dso.mil/groups/big-bang/-/milestones), and [release notes](https://repo1.dso.mil/big-bang/bigbang/-/releases). You don't have to install every release immediately, but avoid skipping the review of releases in between.

> How should I plan and validate a Big Bang upgrade, especially for Istio?

Review the upgrade notices for your target release and the changelog for every package you run — a package change can break a configuration that looks unrelated. Test the upgrade and rollback in staging before production, then verify Flux, Helm releases, and your apps afterward. For Istio specifically, follow the [Migration guides](../migration/index.md) in addition to the [Upgrade guide](../operations/upgrades.md) — the sidecar-to-ambient path is still evolving, so confirm current steps with the team first.

## Getting Help

> How do I report a bug or contribute a fix?

Search [Big Bang work items](https://repo1.dso.mil/big-bang/bigbang/-/issues) first. If it's not already reported, open one with your Big Bang version, Kubernetes version, affected packages, and reproduction steps — never include credentials or sensitive configuration. To contribute a fix, link your merge request to the work item and follow the [Contributing guide](../../CONTRIBUTING.md).
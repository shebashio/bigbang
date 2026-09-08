# UDS Core and Catalog vs. Big Bang: An Architecture Comparison

UDS and Big Bang both provide secure, Kubernetes-based platforms composed from
multiple open source products. They solve many of the same problems: package
delivery, service-mesh integration, network isolation, identity, observability,
policy enforcement, and disconnected operation.

The projects divide those responsibilities differently, however. UDS combines
its baseline platform capabilities and application-integration control plane in
UDS Core, while publishing additional applications as separately maintained
packages. Big Bang keeps its umbrella orchestration, shared integration chart,
and package implementations in independently versioned repositories.

Neither structure is universally better. Each optimizes a different boundary.
This article compares those boundaries and identifies architectural ideas Big
Bang could adopt without copying the complete UDS delivery model.

> This comparison describes project structure and public contracts as of
> September 2026. It is an architectural analysis, not a compatibility claim or
> a proposal to make the two platforms interchangeable.

## A note on the word "catalog"

There is not one obvious public UDS repository literally named the application
catalog. In this article, **UDS package catalog** is shorthand for the ecosystem
of separately maintained application repositories, their published OCI package
artifacts, package metadata, and their presentation through the UDS Registry.

Examples live in the [`uds-packages` GitHub
organization](https://github.com/uds-packages), while UDS documents metadata
used to make packages discoverable in the [UDS
Registry](https://docs.defenseunicorns.com/core/concepts/configuration-and-packaging/package-metadata/).
These application packages are distinct from the platform baseline maintained
in [`uds-core`](https://github.com/defenseunicorns/uds-core).

Big Bang also uses the term catalog in a narrower internal sense. Its
[`chart/package-metadata.yaml`](../chart/package-metadata.yaml) file catalogs
built-in package identities for schema generation and migration tooling. It is
not an artifact registry and does not contain the package implementations.

## The architectures at a glance

| Concern | UDS | Big Bang |
| --- | --- | --- |
| Platform composition | UDS Core is a standard Zarf package assembled from functional layers | The Big Bang umbrella chart renders Flux sources and reconciliation resources |
| Baseline implementation | Core applications, integration operator, policy engine, configuration, and tests live together in `uds-core` | Package charts live in independent repositories; the umbrella owns orchestration and value mapping |
| Application catalog | Separately maintained UDS package repositories and OCI artifacts, discoverable through registry metadata | Core, add-on, community, and user-supplied package repositories selected through Big Bang configuration |
| Application integration contract | A namespaced `Package` custom resource reconciled by the UDS Operator | Helm values rendered by package charts, `bb-common`, or the optional wrapper |
| Runtime ownership | The UDS Operator creates integration resources; downstream controllers consume them | Flux and Helm apply rendered resources; product operators consume their own CRs |
| Release coupling | Core layers and their integration control plane are tested and published from one Core release | Package, `bb-common`, and umbrella releases are independently versioned and coordinated through pins |
| Extension model | Compose Core or functional layers with independently released UDS Packages in a bundle | Enable built-ins or declare custom Git/OCI packages under `packages.<name>` |

This is not a direct comparison of identical artifacts. UDS Core is both a
platform distribution and the home of its application-integration control
plane. The Big Bang repository is primarily an umbrella and GitOps
orchestration layer; it deliberately does not contain the independently
versioned charts that it deploys.

## How UDS divides Core from applications

UDS Core describes itself as a curated secure baseline delivered as one Zarf
package. Its source repository contains functional packages for base services,
identity and authorization, monitoring, logging, runtime security, backup and
restore, and other platform capabilities. The standard Core package imports
those components into one deployable artifact. Individual functional layers
are also published for environments that need a supported subset.

The required base layer includes Istio, the UDS Operator, and the UDS Policy
Engine. Optional functional layers build on that base. This creates a clear
dependency direction:

```text
Core CRDs
  -> Core base: mesh, operator, and policy engine
    -> identity, monitoring, logging, runtime security, and other layers
      -> mission and product applications
```

The key application-facing boundary is the UDS `Package` custom resource. An
application declares intent for concerns such as ingress, allowed traffic,
SSO, service-mesh behavior, and monitoring. The UDS Operator translates that
intent into lower-level resources, including Istio routing and authorization
resources, Kubernetes `NetworkPolicy`, identity-provider configuration, and
Prometheus Operator monitoring resources.

The `Package` resource does not replace those downstream APIs or controllers.
For example, the UDS Operator can own a generated `ServiceMonitor`, while the
Prometheus Operator observes that `ServiceMonitor` and updates Prometheus scrape
configuration. One controller produces a declared input for another:

```text
UDS Package
  -> UDS Operator
    -> ServiceMonitor
      -> Prometheus Operator
        -> Prometheus scrape configuration
```

Applications outside Core are packaged and released separately. A package
normally contains the application delivery definition and a configuration
chart that supplies its UDS-specific declarations. Packages can then be
composed with Core into a deployment bundle. This keeps the platform baseline
cohesive without requiring every optional or mission application to share the
Core release lifecycle.

## What "released in lockstep" means for UDS Core

The UDS Core repository contains the functional-layer definitions, the
operator and CRDs that integrate applications with those layers, common
configuration, policy implementation, end-to-end tests, and publication
workflows. Its standard package imports the functional components from that
same source tree.

The Core release workflow builds and publishes the standard package and its
functional layers from the same release revision. Consequently, a change that
adds a Core capability can update several parts atomically:

- the platform component providing the capability;
- the operator logic that exposes it to applications;
- the `Package` CR schema and validation;
- default policy and configuration;
- integration and upgrade tests;
- the standard package and functional-layer artifacts.

That is the useful meaning of lockstep: these pieces are reviewed and tested as
one platform change and receive a coherent Core version. It does **not** mean
that every upstream product or every catalog application has the same version.
Core still pins independently versioned upstream software, and application
packages outside Core retain their own release lifecycles.

The benefit is a strong compatibility envelope. A Core release can state which
operator behavior, CRD version, policy baseline, and functional-layer versions
were tested together. The cost is a larger release unit: changes to a single
Core concern can trigger broader testing and may increase the impact of a Core
regression.

## How Big Bang divides the same responsibilities

Big Bang uses a more distributed ownership model:

- The [Big Bang umbrella chart](../chart/) owns package enablement, source
  selection, dependency ordering, shared configuration, and Flux
  `HelmRelease` or `Kustomization` generation.
- Each supported package repository owns its chart integration, defaults,
  package-specific tests, and upstream version.
- [`bb-common`](./streamlining-integration-with-bb-common.md) provides shared
  Helm-rendered behavior for cross-cutting concerns such as network policy and,
  increasingly, mesh and authorization integration.
- Community and user-supplied packages retain independent ownership and can be
  selected through `packages.<name>`.
- Flux performs continuous delivery and drift reconciliation for the rendered
  package releases.

The resulting dependency direction is approximately:

```text
Environment values and Big Bang umbrella
  -> Flux source and release objects
    -> independently versioned package chart
      -> upstream chart plus bb-common integration
        -> Kubernetes and product-specific resources
```

Big Bang therefore has a tested release bill of materials, but its source and
release trains are decoupled. A `bb-common` change is released, then adopted by
package repositories, and finally consumed through versions pinned or selected
by the umbrella. This permits package teams to move independently, but a
cross-cutting behavior change may require coordinated changes and validation
across several repositories.

The umbrella's built-in package metadata catalog improves consistency within
that model. It gives built-in packages stable identities and generates schema
and migration views, while the unified `packages.<name>` contract makes
built-in and user-supplied packages easier to configure. It does not currently
provide a runtime application-intent API comparable to the UDS `Package`
resource.

## Where UDS has an architectural advantage

### A first-class application-to-platform contract

The UDS `Package` CR separates application intent from platform implementation.
Application teams describe the access, identity, and observability behavior
they need. The platform can change how it fulfills that request without forcing
each application to render a new implementation-specific resource shape.

Because the contract exists in the cluster, it can also expose status. An
operator can report whether networking, SSO, routing, and monitoring were
accepted and reconciled. Big Bang's current Helm values are effective desired
configuration, but they are not independently observable runtime objects with
a unified readiness contract.

### Platform integration and platform capabilities evolve together

Keeping Core integration logic beside the functional layers reduces the delay
between changing a platform capability and making it consumable by
applications. Schema, reconciliation, provider behavior, and end-to-end tests
can move in one pull request and one Core release.

### A clearer platform/application ownership boundary

Core owns how networking, identity, and observability are implemented.
Application packages own their workloads and declare what they need through the
platform API. This reduces the need for every application chart to understand
low-level Istio, Keycloak, or Prometheus implementation details.

### Consistent integration for applications outside the platform bundle

A mission application can use the same CR whether it is delivered in the Core
bundle, another UDS bundle, or through a separate deployment process. The
contract is Kubernetes-native rather than tied to one umbrella values tree.

## Where Big Bang has an architectural advantage

### Independent package ownership and release cadence

Package teams can update, test, and release their integration without waiting
for all platform implementation to move in the same repository. The umbrella
selects known versions rather than making every package part of one source
release. This limits source coupling and aligns well with products that already
have distinct maintainers and upstream cadences.

### GitOps-visible composition

The umbrella renders explicit Flux sources and releases. Operators can inspect
the selected repository, version, values, dependency ordering, and
reconciliation state using standard Flux and Helm concepts. Big Bang does not
need a privileged application-integration controller for its existing package
model.

### Flexible package sources and implementation choices

Big Bang can compose supported and user-supplied packages from Git or OCI Helm
sources and can use Helm or Kustomize reconciliation. Packages with advanced or
unusual needs can own native Kubernetes resources instead of being constrained
by the fields supported by a central application CR.

### Smaller failure domains for package implementation

A defect in one package repository does not necessarily require changing or
republishing every other package. Although umbrella integration testing remains
important, implementation and release responsibility can stay close to the
team that understands the application.

## The tradeoff in plain language

UDS centralizes **platform semantics** and lets application artifacts remain
separate. Big Bang decentralizes more of the **integration implementation** as
well as the application artifacts.

The UDS approach tends to improve consistency, runtime visibility, and the
speed of platform-wide integration changes. It also creates a powerful
controller with broad responsibilities and makes the Core repository and
release a larger coordination and failure domain.

The Big Bang approach tends to improve package autonomy, explicit GitOps
composition, and compatibility with arbitrary Helm software. It also makes
cross-cutting changes slower to propagate and ties the application-facing
integration contract to Helm values and package release coordination.

## A possible Big Bang hybrid

Big Bang does not need to adopt the complete UDS repository or Zarf packaging
strategy to gain the benefit of a stable runtime integration API. A phased
architecture could preserve the existing package ecosystem while adding a Big
Bang-specific `ApplicationIntegration` custom resource and controller.

Three ownership modes would make the transition explicit:

| Mode | Intent owner | Generated-resource owner | Likely consumer |
| --- | --- | --- | --- |
| `Direct` | Package Helm values | Helm through `bb-common` | Existing packages and platform substrate |
| `EmittedCR` | Package chart or `bb-common` | Integration controller | Migrated team-maintained packages |
| `NativeCR` | Mission GitOps repository | Integration controller | Mission and arbitrary applications |

Initially, maintained packages could continue using `bb-common` directly while
mission applications exercise the CR and controller in explicitly authorized
namespaces. After the API demonstrates equivalent security behavior,
`bb-common` could become a compatibility and authoring layer: it would translate
supported values into the CR instead of directly rendering overlapping
resources. The controller would then own generated `NetworkPolicy`,
`AuthorizationPolicy`, routing, authentication, and monitoring resources.

Direct rendering would remain appropriate for bootstrap components needed to
run the controller itself, including Flux, the controller and its CRDs, the
service-mesh control plane, policy engines, identity infrastructure, and
monitoring operators. It would also remain available for resource types not yet
represented by the API and for documented exceptions.

The most important rule would be exclusive ownership. Helm and the controller
must never manage the same integration resource simultaneously. Migration
would need conformance fixtures, clear field ownership, fail-closed ordering,
upgrade and rollback tests, and explicit graduation gates.

This hybrid preserves Big Bang's independently maintained package repositories
and Flux-based delivery while creating a stable application-to-platform
contract for cases where chart coupling is currently the largest obstacle.

## Conclusion

The strongest part of the UDS architecture is not simply that it has separate
Core and application repositories. Big Bang already separates its umbrella
from package repositories. The more consequential difference is that UDS Core
keeps the platform capabilities, application-integration API, controller,
policy behavior, and their conformance tests inside one release boundary.

Big Bang's distributed model remains valuable for package autonomy and GitOps
transparency. Its clearest opportunity is therefore selective convergence:
retain independent packages and `bb-common`, but introduce a stable runtime
contract where mission applications and common application-layer integration
would benefit from it. That would capture much of UDS Core's consistency and
runtime visibility without giving up the package and release flexibility that
Big Bang already provides.

## References

- [UDS Core overview](https://docs.defenseunicorns.com/core/concepts/overview/)
- [UDS Core functional layers](https://docs.defenseunicorns.com/core/concepts/platform/functional-layers/)
- [UDS platform and application-layer boundary](https://docs.defenseunicorns.com/core/concepts/platform/platform-vs-app-layer/)
- [UDS Core CRDs](https://docs.defenseunicorns.com/core/concepts/configuration-and-packaging/crd-overviews/)
- [UDS package requirements](https://docs.defenseunicorns.com/core/concepts/configuration-and-packaging/package-requirements/)
- [UDS package metadata](https://docs.defenseunicorns.com/core/concepts/configuration-and-packaging/package-metadata/)
- [UDS Core repository](https://github.com/defenseunicorns/uds-core)
- [UDS package repositories](https://github.com/uds-packages)
- [Big Bang package management](../docs/concepts/package-management.md)
- [Big Bang extra package deployment](../docs/installation/environments/extra-package-deployment.md)
- [Big Bang unified package configuration ADR](../docs/community/adrs/0011-unified-package-configuration-and-metadata.md)
- [Streamlining package integration with `bb-common`](./streamlining-integration-with-bb-common.md)

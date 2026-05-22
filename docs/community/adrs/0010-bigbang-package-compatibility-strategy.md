# ADR: Decouple Big Bang Package Deployment from Compatibility Validation

## Status

Proposed

## Context

Big Bang currently uses an umbrella Helm chart to define and deploy many packages as Flux `HelmRelease` resources. This model has historically provided two benefits:

1. It gives users a single deployment entry point.
2. It implies that the package versions included in the umbrella have been validated together.

As Big Bang has grown, the umbrella chart has accumulated many packages, including packages that are not strictly part of the core platform. This increases the cost of testing, releasing, upgrading, and maintaining the umbrella. It also couples package release cadence to Big Bang release cadence, even when individual packages have not changed.

The desired future state is to slim the umbrella chart so that it focuses primarily on core platform and stateless foundational packages, such as:

- Istio
- Kyverno
- policy primitives
- common GitOps/Flux conventions
- core platform security and networking assumptions

At the same time, Big Bang still needs to preserve a strong compatibility guarantee between:

- Big Bang umbrella/core versions
- package versions
- profile versions
- shared integration behavior provided by `bb-common`

Recent adoption of the `bb-common` Helm library chart affects this design. `bb-common` is included as a pinned subchart dependency in Big Bang packages and provides helper templates for common integration resources such as:

- Istio-related resources
- network policies
- authorization policies
- routes and ingress-related resources

Because `bb-common` is pinned in each package artifact, many implementation details are already captured by the package’s Helm dependency metadata and do not need to be duplicated in a separate compatibility matrix.

## Decision

We will decouple package deployment ownership from compatibility validation.

The Big Bang umbrella chart will move toward a thinner core-platform role. Optional or higher-level packages will move out of first-class umbrella ownership and into validated profiles or external package compositions.

Compatibility will be preserved through three primary artifacts:

1. **Big Bang release compatibility manifest**
2. **Package integration metadata**
3. **Profile composition lock/manifest**

These artifacts will replace the current implicit assumption that “included in the umbrella” means “compatible.”

The guiding principle is:

> The package says what it needs.  
> The profile says what it composes.  
> Big Bang says what it validated.

---

## Compatibility and Contract Artifacts

### 1. Big Bang Release Compatibility Manifest

The Big Bang release compatibility manifest is the official release-level compatibility guarantee.

#### Location

The manifest should live in the Big Bang umbrella/core repository and be published as a Big Bang release artifact.

Example:

```text
bigbang/
  compatibility/
    bigbang-3.25.0.yaml
```

#### Purpose
It answers:
> For this Big Bang release, which profiles and package versions are validated, carried forward, allowed, or blocked?

Example:
`
bigBangVersion: 3.25.0

core:
  istio: 1.25.3-bb.0
  kyverno: 1.14.4-bb.1

integrationContracts:
  networkPolicies: v2
  istioResources: v1
  kyvernoPolicies: v1

validatedProfiles:
  observability:
    version: 2026.05.18
    status: validated

  security-tools:
    version: 2026.05.18
    status: validated

validatedPackages:
  grafana:
    version: 8.6.1-bb.1
    status: validated-standalone

blockedPackages:
  - package: tempo
    versions: "<1.18.0-bb.1"
    reason: "Older package versions render network policies incompatible with the current default-deny posture."
`

Notes

The Big Bang compatibility manifest should not become a second Chart.lock.

It should not duplicate every package’s pinned bb-common dependency. That dependency is already part of the package artifact.

Instead, the manifest should capture:

* validated profile versions
* independently validated package versions
* compatibility status
* blocked versions
* carried-forward compatibility assertions
* integration contract versions relevant to the Big Bang release
* core platform package versions
* validation evidence, where useful

### 2. Package Integration Metadata
Each package should include lightweight metadata describing its Big Bang integration surface.
This is not the official Big Bang compatibility manifest. It is package-local metadata.

#### Location
The metadata should live inside the package repository and should be included in the package artifact.

Example:
grafana-8.6.1-bb.1.tgz
  Chart.yaml
  Chart.lock
  values.yaml
  templates/
  bb-package.yaml
  CHANGELOG.md
  upgrade-notices.md

Possible file names:
- bb-package.yaml
- contract.yaml
- package-metadata.yaml

Recommended file name:
- bb-package.yaml

#### Purpose
It answers: What Big Bang integration capabilities does this package use, and what assumptions must be validated?

#### Example fields in package metadata

`
package: grafana
packageVersion: 8.6.1-bb.1
upstreamVersion: 11.5.2

bbCommonCapabilities:
  networkPolicies: true
  routes: true
  authorizationPolicies: false
  peerAuthentications: false
  sidecars: false

integrationInterface:
  domain:
    requirement: required
    source: profile-or-user
    reason: "Used to construct external route hostnames."

  hostname:
    requirement: defaulted
    default: grafana
    overrideAllowed: true

  networkPolicies.enabled:
    requirement: defaulted
    default: true
    overrideAllowed: true
    compatibilityRelevant: true
    reason: "Disabling this changes the validated security posture."

  istio.enabled:
    requirement: defaulted
    default: true
    overrideAllowed: true
    compatibilityRelevant: true

validation:
  required:
    - helm-template
    - install
    - upgrade
    - helm-test
    - kyverno-policy-check
    - network-policy-render-check
    - network-policy-connectivity-check
    - route-render-check
    - route-reachability-check
`

upgradeNotices:
  - id: grafana-custom-sidecar-values
    severity: notice
    text: "Users overriding sidecar values should verify compatibility with the current network policy contract."

### 3. Profile Composition Lock/Manifest


#### Couple of assumptions/assertions
1. Big Bang umbrella today provides deployment ownership and compatibility validation. i.e. it deploys a package and proves it works with the rest of the platform.
1. We want to slim down umbrella (remove deployment ownership) without losing compatibility validation.
1. Today, removing packages means less compatibility validation and testing (less guarantee that package A works with package B or package A works with core umbrella features such as Istio and Kyverno versions)
1. We still need to validate that packages cleanly install as big bang umbrella is updated
1. 

### Proposed strategy
1. Create "validated profile" concept. Groupings of validated packages with each Big Bang release, i.e. observability-profile, logging-profile, gitlab-profile etc..
1. First profile will be Nexus profile as an MVP since Nexus already lives outside the umbrella as a bb product team maintained package.
1. Create a compatibility matrix that's published with each big bang release - defines which package versions ( packages not embedded in the umbrella ) are tested per profile and release

`
bigBangVersion: 3.25.0
releasedAt: 2026-05-18

core:
  istio:
    version: 1.25.3-bb.0
    status: deployed-by-umbrella
  kyverno:
    version: 1.14.4-bb.1
    status: deployed-by-umbrella

validatedPackages:
  grafana:
    version: 8.6.1-bb.0
    status: validated
    validationRun: pipeline-123456
    profiles:
      - observability
  loki:
    version: 6.27.0-bb.2
    status: validated
    validationRun: pipeline-123457
    profiles:
      - observability

notRetested:
  gitlab:
    version: 8.11.4-bb.0
    status: previously-validated
    lastValidatedWith: 3.24.0
    reason: not in default release matrix
`
status options - validated, previously-validated, blocked

1. Every package MR runs helm render, schema, policy, deprecated APIs, clean install with umbrella, upgrade with umbrella, and package helm tests.
Package testing should validate - 
* All pods ready
* HelmRelease reconciled
* no Kyverno policy violations
* no deprecated APIs
* service reachable with Istio enabled
* mTLS behavior correct
* default-deny network policies do not break core traffic
* upgrade from previous validated version succeeds
* package-specific Helm tests pass
* package images match expected versions

1. Every profile has a clean install job that runs nightly
1. Still maintain live, static release clusters that contain profiles of packages
1. Profiles live in the customer-template repo. 
1. Profiles are released in coordination with big bang but are not part of the big bang release directly
1. Big Bang release validates the profiles but does not own every package directly

### Profile Definitions
`
profile: observability
version: 2026.05.18

compatibleWith:
  bigBang:
    - 3.25.0
  integrationContracts:
    istioResources: v1
    networkPolicies: v2
    kyvernoPolicies: v1

packages:
  grafana: 8.6.1-bb.1
  loki: 6.27.0-bb.3
  tempo: 1.18.0-bb.1

status: validated
validationEvidence:
  pipeline: "123456"
  testedAt: "2026-05-18"
`

### Package contract strategy
1. Each package owns a machine- readable compatiblity declaration
packages/grafana/
  chart/
  CHANGELOG.md
  bb-package.yaml
  upgrade-notices.md
  tests/

`
name: grafana
packageVersion: 8.6.1-bb.0
upstreamVersion: 11.5.2

contracts:
  istio:
    required: true
    ingress: true
    mtls: supported
  kyverno:
    baseline: required
  networkPolicies:
    defaultDenyCompatible: true
  monitoring:
    serviceMonitor: supported

compatibility:
  bigBang:
    min: 3.24.0
    maxTested: 3.25.0
  kubernetes:
    min: 1.29
    max: 1.31
`

### Migration strategy / Bridge
1. Use "extra package" deployment definition in Umbrella to migrate packages. First migrate from core/addons section to `packages:`
1. Extra package deployment migration path provides users with a transition 

### Community / BYO Package
1. Not guaranteed by release but can self-certify against the release. Publishes -> compatible with BB version x

### Criteria for defining core umbrella packages
* Is it stateless?
* Does it define platform behavior?
* Does it require Big Bang-specific values transformation?
* Does it depend on Istio/Kyverno/network policy integration?
* Is it required by the DevSecOps reference architecture?
* Is it operationally expensive to test?
* Is it frequently customized by customers?

### Preferred end state
1. Big Bang Umbrella:
  deploys only core platform primitives

2. Umbrella Compatibility Manifest:
  declares tested package/profile combinations

3. Package Contracts:
  define what each external package must prove

4. Profile repos:
  compose optional capabilities

5. CI matrix:
  validates Big Bang core + package contracts + named profiles

6. Release notes:
  publish what changed, what moved, and what is guaranteed

Compatibility matrix becomes the product - not the umbrella chart. Umbrella - small, stable core.
Release process proves that the larger ecosystem still works around core.

## Ownership model
Big Bang repo
  Owns release-level compatibility guarantee

Package repos
  Own package-level contract metadata and dependency pins

Profiles repo
  Owns validated package compositions
# 12. Application Integration API

Date: 2026-09-01

## Status

Proposed

## Context

Big Bang packages currently declare platform integration through Helm values consumed by
`bb-common`. This provides consistent generation of network policies, Istio resources,
inbound and outbound routes, authorization policies, and other supporting resources.
It also requires an application to include `bb-common` as a chart dependency or arrange
for a separate `bb-common` Helm release. Platform integration is therefore tied to Helm
rendering and to the release lifecycle of each application chart.

This model creates several problems as the package ecosystem grows:

- application packages depend on the current structure of `bb-common` values;
- changing a platform integration may require coordinated releases of `bb-common`, an
  application package, and the Big Bang umbrella chart;
- applications deployed outside the Big Bang umbrella require a separate Helm or
  Kustomize integration pattern;
- the cluster has no first-class object showing whether an application's networking,
  authentication, and observability integrations are ready;
- implementation details such as Istio `VirtualService`, `AuthorizationPolicy`, and
  Prometheus `ServiceMonitor` appear in the application-facing configuration contract;
- identical intent may be represented differently by Big Bang packages, mission
  applications, and applications managed by Argo CD.

Big Bang needs a namespaced, declarative API that lets an application state its platform
integration intent without owning the implementation. The API must preserve Big Bang's
secure defaults, optional package backends, Flux lifecycle, and use of standard
Kubernetes APIs.

## Decision

Big Bang will introduce an `ApplicationIntegration` custom resource reconciled by a Big
Bang application integration controller.

Big Bang will evaluate the API through a phased dual-path adoption. Existing
team-maintained packages continue to use direct `bb-common` resource generation while
the API and controller are incubating. Mission applications or "user defined" packages are
the first controller consumers. After the controller satisfies the graduation gates in
this ADR, maintained application packages may migrate by having `bb-common` emit an
`ApplicationIntegration` instead of directly rendering overlapping platform resources.

Direct rendering remains supported for the platform substrate and approved exceptions.
The phased model is intended to converge application-layer integrations on one semantic
contract; it is not intended to establish two unrelated permanent integration standards.

The initial API is:

```yaml
apiVersion: platform.bigbang.dev/v1alpha1
kind: ApplicationIntegration
```

`v1alpha1` is an incubation version, not a promise of API stability. The API will become
`v1beta1` only after it has been exercised by representative Big Bang packages and
mission applications. The compatibility guarantees in [API evolution](#api-evolution)
apply as versions graduate.

An `ApplicationIntegration` declares application intent for:

- workload identity and selection;
- service exposure through Gateway API;
- platform-provided authentication and coarse authorization;
- default-deny network policy with explicit allowed flows;
- service-mesh enrollment and mutual TLS;
- metrics collection and endpoint probing.

It does not deploy the application. Flux, Helm, Argo CD, or another workload delivery
mechanism remains responsible for the application Deployment, StatefulSet, Service,
Secrets, and application-specific configuration.

### Resource scope

`ApplicationIntegration` is namespace scoped. A resource may only select workloads and
Services in its own namespace. Multiple resources may exist in a namespace, allowing
independently secured applications to share a namespace without combining their entire
integration contract.

Cross-namespace access is explicit through typed references. A reference is not valid
merely because the target object exists: the target namespace or platform policy must
also permit the reference. A cross-namespace Gateway parent reference must be permitted
by the Gateway listener's `allowedRoutes`; other Gateway API cross-namespace object
references use `ReferenceGrant` where the Gateway API specification requires it.

### Application-facing API

The proposed top-level shape is:

```yaml
spec:
  className: default
  workloads: []
  mesh: {}
  exposures: []
  network: {}
  observability: {}
```

Unknown fields are rejected. Raw Kubernetes objects and arbitrary Helm values are not
accepted inside the resource. Advanced or implementation-specific behavior is expressed
with the native resource beside the `ApplicationIntegration`, not embedded as an
unvalidated escape hatch.

#### `className`

`className` is required, immutable, and selects a cluster-scoped
`ApplicationIntegrationClass`. The class identifies the controller and cluster
capabilities used to satisfy the request. A class can select platform implementations
such as Gateway API with Istio, Authservice with an external OIDC provider, Prometheus
Operator, or an approved alternative.

The companion administrative resource has this shape:

```yaml
apiVersion: platform.bigbang.dev/v1alpha1
kind: ApplicationIntegrationClass
metadata:
  name: default
spec:
  controllerName: platform.bigbang.dev/application-integration-controller
  parametersRef:
    apiGroup: platform.bigbang.dev
    kind: BigBangIntegrationParameters
    name: default
status:
  supportedFeatures:
    - HTTPRoute
    - StrictMTLS
    - ProxyAuthentication
    - ServiceMonitor
```

`ApplicationIntegrationClass` and its parameter object are owned by platform
administrators. Parameter fields are controller configuration and do not become part of
the application-facing API.

The class is cluster configuration, not application configuration. Applications cannot
use it to weaken mandatory platform policy. The class mechanism follows the separation
used by `GatewayClass` and `StorageClass`: the application contract remains stable while
platform implementations can change.

#### `workloads`

`workloads` gives stable names to groups of pods within the resource's namespace:

```yaml
workloads:
  - name: web
    selector:
      matchLabels:
        app.kubernetes.io/name: podinfo
        app.kubernetes.io/component: web
    serviceAccounts:
      - podinfo
```

Each entry contains:

- a DNS-label `name`, unique within the resource;
- a non-empty Kubernetes label `selector`;
- the ServiceAccount names expected for matching pods.

Selectors may be updated, but a selector change transfers network and authorization
policy to a different set of pods and must be treated as a security-sensitive GitOps
change. Empty selectors and overlapping workload selectors within one resource are
rejected. If separate `ApplicationIntegration` resources select the same pod, neither is
Accepted until the conflict is resolved.

The controller reports a warning when selected pods use an undeclared ServiceAccount.
Authorization policies use ServiceAccount identities where the selected mesh supports
them. Kubernetes `NetworkPolicy` continues to use pod and namespace selectors.

#### `mesh`

`mesh` describes the required behavior, not the installed service-mesh implementation:

```yaml
mesh:
  mode: PlatformDefault
  mtls: Strict
```

Supported initial values are:

- `mode`: `PlatformDefault`, `Ambient`, `Sidecar`, or `Disabled`;
- `mtls`: `Strict` or `PlatformDefault`.

`PlatformDefault` is the default for both fields. A class may reject `Ambient`,
`Sidecar`, or `Disabled` when that choice conflicts with cluster policy or installed
capabilities. `Disabled` is never an implicit fallback and cannot be used to bypass
mandatory authorization or network policy.

The controller may apply namespace labels or workload annotations only when the selected
class explicitly enables mutation. Otherwise it validates enrollment and reports a
`MeshReady=False` condition with remediation guidance. This avoids two controllers
silently fighting over workload metadata.

#### `exposures`

`exposures` declares simple HTTP or HTTPS entry points:

```yaml
exposures:
  - name: web
    target:
      workload: web
      service:
        name: podinfo
        port: http
    gatewayRefs:
      - name: public
        namespace: istio-gateway
    hostnames:
      - podinfo.apps.example.mil
    authentication:
      mode: Proxy
      providerRef:
        name: default
      client:
        id: podinfo
        secretRef:
          name: podinfo-oidc
      authorization:
        groups:
          anyOf:
            - /podinfo/users
```

Each exposure contains:

- a unique name;
- a workload and Service target in the same namespace;
- one or more Gateway API Gateway references;
- explicit hostnames;
- optional simple path and method matches;
- an authentication mode and authorization requirements.

The target Service must select pods contained by the referenced workload selector. The
controller rejects or marks NotReady an exposure that would route to workloads outside
the declared integration boundary.

`authentication.mode` is required for every exposure so that unauthenticated exposure is
always an explicit choice. The initial modes are:

- `None`: no platform-provided end-user authentication;
- `Native`: validate tokens for an application that implements its own OIDC flow;
- `Proxy`: protect the endpoint through the class-provided authentication proxy.

The class may prohibit `None` for selected gateways or namespaces. `None` means only
that this API does not provide end-user authentication; it does not disable workload
identity, mesh authorization, or network policy.

`providerRef` identifies a cluster-approved identity provider configuration. Secret
values are never stored in the custom resource. `secretRef` names a Secret in the
application namespace. Provider implementations may populate that Secret when they
support client registration, or validate a Secret provisioned by the environment.

Group rules provide a coarse platform access gate. Application-specific authorization
and business permissions remain the application's responsibility.

The controller generates Gateway API `HTTPRoute` resources for this portable subset.
Applications needing advanced Gateway API behavior create native `HTTPRoute`,
`GRPCRoute`, `TCPRoute`, or `TLSRoute` resources. The integration API will not reproduce
the complete Gateway API schema.

#### `network`

Network access is default deny:

```yaml
network:
  defaultDeny:
    ingress: true
    egress: true
  ingress:
    - name: gateway-to-web
      to:
        workload: web
        ports:
          - name: http
            protocol: TCP
      from:
        - gatewayRef:
            name: public
            namespace: istio-gateway
  egress:
    - name: web-to-database
      from:
        workload: web
      to:
        - workload:
            namespace: database
            selector:
              matchLabels:
                app.kubernetes.io/name: postgres
          ports:
            - number: 5432
              protocol: TCP
    - name: external-api
      from:
        workload: web
      to:
        - cidr: 192.0.2.10/32
          ports:
            - number: 443
              protocol: TCP
```

Both `defaultDeny.ingress` and `defaultDeny.egress` default to `true`. A class may enforce
them even if an application requests `false`.

Initial peer types are:

- another workload in the same `ApplicationIntegration`;
- a pod and namespace selector;
- a ServiceAccount plus pod and namespace selector;
- a Gateway reference;
- an approved platform capability such as DNS, monitoring, or the Kubernetes API;
- a CIDR.

The controller generates Kubernetes `NetworkPolicy` and, when supported by the selected
class, mesh authorization policy from the same declared flow. It reports which layers
enforce each rule.

DNS names are not accepted as network-policy destinations in the initial API. Standard
Kubernetes `NetworkPolicy` cannot enforce a DNS name safely, and silently translating a
name to changing IP addresses would overstate the protection. External hostname support
may be added when an installed egress implementation can enforce it and expose that
capability through the selected class.

Default rules required for DNS, mesh control-plane traffic, health checks, and platform
monitoring are owned by the integration class. Applications may request a named platform
capability but do not reproduce its namespaces, selectors, or ports.

#### `observability`

`observability` declares metrics and availability checks:

```yaml
observability:
  metrics:
    - name: application
      target:
        service:
          name: podinfo
          port: metrics
      path: /metrics
      interval: 30s
      scheme: http
  probes:
    - name: web
      exposure: web
      path: /healthz
      interval: 30s
```

The controller generates a `ServiceMonitor`, `PodMonitor`, or equivalent selected by the
integration class. It also generates the network and mesh authorization required for
the configured monitoring backend to reach the target.

Metrics credentials use Secret references. Inline credentials are prohibited. Log
collection is not part of the initial API because Big Bang collectors normally discover
container logs without per-application resources. Dashboard content, alert expressions,
and tracing configuration remain native resources until a portable contract is proven.

### Complete example

```yaml
apiVersion: platform.bigbang.dev/v1alpha1
kind: ApplicationIntegration
metadata:
  name: podinfo
  namespace: podinfo
spec:
  className: default

  workloads:
    - name: web
      selector:
        matchLabels:
          app.kubernetes.io/name: podinfo
      serviceAccounts:
        - podinfo

  mesh:
    mode: PlatformDefault
    mtls: Strict

  exposures:
    - name: web
      target:
        workload: web
        service:
          name: podinfo
          port: http
      gatewayRefs:
        - name: public
          namespace: istio-gateway
      hostnames:
        - podinfo.apps.example.mil
      authentication:
        mode: Proxy
        providerRef:
          name: default
        client:
          id: podinfo
          secretRef:
            name: podinfo-oidc
        authorization:
          groups:
            anyOf:
              - /podinfo/users

  network:
    defaultDeny:
      ingress: true
      egress: true
    egress:
      - name: external-api
        from:
          workload: web
        to:
          - cidr: 192.0.2.10/32
            ports:
              - number: 443
                protocol: TCP

  observability:
    metrics:
      - name: application
        target:
          service:
            name: podinfo
            port: metrics
        path: /metrics
        interval: 30s
        scheme: http
    probes:
      - name: web
        exposure: web
        path: /healthz
        interval: 30s
```

## Reconciliation contract

The controller uses server-side apply with a dedicated field manager. Generated objects
carry labels identifying the source `ApplicationIntegration`, API version, feature, and
integration class. Namespaced generated objects have an owner reference to the source
resource.

The controller may create:

| Declared intent | Initial generated resources |
| --- | --- |
| Exposure | Gateway API `HTTPRoute` |
| Default-deny and allowed traffic | Kubernetes `NetworkPolicy` |
| Mesh enrollment and mTLS | Implementation-specific mesh policy |
| Workload authorization | Mesh authentication and authorization policy |
| Proxy authentication | Authservice and identity-provider integration resources |
| Metrics | `ServiceMonitor` or `PodMonitor` |
| Availability probe | Prometheus blackbox `Probe` or class equivalent |

The mapping is controller implementation, not part of the application API. Changing from
an Istio `VirtualService` implementation to Gateway API `HTTPRoute`, or from one metrics
backend to another, does not require changing an application's declared intent when the
new implementation satisfies the same semantics.

The controller does not adopt an existing resource unless it already identifies the same
source resource and controller field manager. A name or field ownership conflict results
in `Conflict=True`; the controller does not force ownership away from Flux, Helm, or
another controller.

Reconciliation establishes protections before reachability. The controller applies
default-deny policy first, then allowed flows and requested authentication, and only then
attaches an externally reachable route. An exposure requesting authentication must not
become reachable while authentication is NotReady. During an unsuccessful update, the
controller retains the last known safe configuration rather than removing a working
control before its replacement is ready.

Deleting an `ApplicationIntegration` removes owned in-cluster resources. External
identity clients are retained by default. A future explicit deletion policy may allow
provider cleanup after the behavior is proven safe. Finalizers must not make application
namespace deletion depend indefinitely on an unavailable external identity provider.

## Status contract

Status provides one observed-generation result rather than requiring an operator to
inspect every generated resource:

```yaml
status:
  observedGeneration: 4
  className: default
  conditions:
    - type: Accepted
      status: "True"
      reason: Valid
    - type: NetworkReady
      status: "True"
      reason: Reconciled
    - type: ExposureReady
      status: "True"
      reason: RoutesAccepted
    - type: AuthenticationReady
      status: "True"
      reason: ClientConfigured
    - type: ObservabilityReady
      status: "True"
      reason: TargetsReady
    - type: Ready
      status: "True"
      reason: AllIntegrationsReady
  resources:
    - apiVersion: gateway.networking.k8s.io/v1
      kind: HTTPRoute
      namespace: podinfo
      name: podinfo-web
```

Condition type names are part of the served-version API contract. Reasons and messages
may expand without changing the schema. `Ready=True` requires every requested integration
to be available and successfully reconciled. Optional backends never fail open: if an
application requests proxy authentication and Authservice or the identity provider is
unavailable, `AuthenticationReady=False` and `Ready=False`.

The controller publishes Kubernetes Events for actionable transitions, but Events are
not the durable status API.

## Security invariants

The following rules apply independently of the selected integration class:

1. The controller never stores plaintext credentials in the resource, status, Events,
   or logs.
2. Network access is default deny unless cluster policy explicitly provides a stricter or
   documented alternative.
3. Missing requested security capabilities fail closed and produce a NotReady condition.
4. A namespaced application cannot select or mutate workloads in another namespace.
5. Cross-namespace references require explicit authorization.
6. The API has no raw-object, arbitrary-template, or Helm-values escape hatch.
7. Policy exceptions are separate, auditable resources. They are not embedded in the
   application integration request.
8. Generated resource ownership is explicit; the controller does not seize fields from
   Flux, Helm, or another controller.
9. Status distinguishes requested intent, generated resources, and enforcement layers so
   operators are not told a flow is protected by both network and mesh policy when only
   one is active.
10. External reachability is established only after the requested network and
    authentication controls are ready.

## Adoption strategies

The custom resource can be adopted through several strategies. The API shape does not
depend on which strategy is selected.

### Immediate convergence

All application packages could migrate from direct `bb-common` resource generation to
`ApplicationIntegration` in one coordinated release. This would establish one mechanism
quickly, but it would require near-complete feature parity before the controller had
production experience. It would also give the new controller a large privilege and
application scope from its first release.

### Phased convergence

Existing packages can remain on direct `bb-common` while the operator is introduced for
mission applications in explicitly authorized namespaces. Representative maintained
packages can then migrate after the API demonstrates equivalent security behavior.

This is the proposed adoption strategy. It reduces initial migration and privilege risk
while retaining convergence on a common application contract as the long-term goal.

### Permanent separation

Maintained packages could always use direct `bb-common` while arbitrary applications
always use the controller. This provides a simple organizational boundary, but it would
create two permanent integration dialects. Defaults, ambient behavior, authentication,
and security fixes could diverge, and platform changes would require two implementations
and test suites. Permanent separation is not the intended outcome.

## Integration ownership modes

During phased adoption, Big Bang supports three mutually exclusive ownership modes:

| Mode | Intent owner | Generated-resource owner | Initial consumers |
| --- | --- | --- | --- |
| `Direct` | Helm values | Helm and Flux through `bb-common` | Existing and bootstrap packages |
| `EmittedCR` | Helm owns the CR | Integration controller | Migrated maintained packages |
| `NativeCR` | Mission GitOps owner | Integration controller | Mission and arbitrary applications |

In `Direct` mode, `bb-common` renders platform resources and Helm owns them. No
`ApplicationIntegration` is created.

In `EmittedCR` mode, the application chart or `bb-common` renders an
`ApplicationIntegration`. Helm owns the custom resource, and the integration controller
exclusively owns its generated resources.

In `NativeCR` mode, a mission application's GitOps repository owns the
`ApplicationIntegration`, and the integration controller owns its generated resources.

An application must not use more than one mode for the same integration feature.
Admission checks, ownership labels, and conformance tests prevent Helm and the controller
from managing the same resource. The exact `bb-common` configuration used to select a
mode will be finalized through implementation experience. A candidate interface is:

```yaml
bb-common:
  applicationIntegration:
    mode: Direct # Direct or EmittedCR
```

## Phased adoption plan

### Phase 0: Contract and conformance

Before deploying the controller:

1. define the CRDs and structural schemas;
2. create fixtures expressing equivalent intent through `bb-common` values and an
   `ApplicationIntegration`;
3. establish expected generated resources and security behavior;
4. define resource names, field ownership, and controller RBAC;
5. test fail-closed reconciliation ordering.

Phase 0 is complete when network, routing, authentication, and monitoring conformance
fixtures exist; the API and RBAC have completed security review; and no ambiguous
resource-ownership cases remain.

### Phase 1: Mission applications

Deploy the controller for explicitly authorized mission namespaces while maintained
packages remain in `Direct` mode. The first supported surface should be limited to HTTP
exposure, default-deny policy, explicit network flows, mesh enrollment, and metrics.
Proxy authentication is included only when its fail-closed behavior is ready.

Phase 1 is complete when:

- at least one application outside the Big Bang umbrella uses the API;
- controller upgrade and outage tests pass;
- generated protections remain effective while the controller is unavailable;
- Flux and controller ownership-conflict tests pass;
- controller metrics, alerts, and operational runbooks are available.

### Phase 2: Representative maintained packages

Allow selected packages to enter `EmittedCR` mode. The group must cover a simple HTTP
application, Authservice, ambient mode, multiple workloads or stateful traffic, metrics,
and endpoint probes.

Phase 2 is complete when:

- direct and controller-managed configurations pass equivalent security tests;
- package upgrade tests cover the transition between ownership modes;
- rollback to direct management is documented and tested;
- no overlapping Helm and controller ownership remains after migration.

### Phase 3: Application-layer convergence

New application packages prefer `ApplicationIntegration`, and existing application
packages migrate during normal releases. Direct rendering becomes a compatibility path,
overlapping `bb-common` fields may begin deprecation, and the API can be evaluated for
beta graduation.

### Phase 4: Permanent substrate boundary

Direct Helm or native resource management remains appropriate for components needed to
bootstrap or provide the integration controller:

- Flux;
- the integration CRDs, conversion webhooks, and controller;
- Istio control plane and gateways;
- policy engines;
- monitoring operators and CRDs;
- identity-provider infrastructure.

This boundary avoids a circular dependency:

```text
Flux and Helm
  -> install the platform substrate
    -> install the integration controller
      -> reconcile application integrations
```

Application-layer packages should converge on `EmittedCR` or `NativeCR`. Continued
`Direct` use outside the substrate requires an explicit, documented exception.

## Relationship to `bb-common`

`bb-common` remains the supported Helm integration mechanism during incubation and
migration. Its existing values and tests provide the starting semantics for network
policy, routes, Istio, authorization, and Authservice behavior.

The custom resource is not implemented by invoking Helm or embedding the `bb-common`
chart in the controller. Runtime reconciliation must use a typed implementation library
and Kubernetes clients. Helm rendering inside a controller would preserve the current
coupling and make field ownership and upgrades difficult to reason about.

For packages in `EmittedCR` mode, `bb-common` acts as a compatibility and authoring layer:
it translates supported existing values into an `ApplicationIntegration` instead of
rendering the overlapping resources. This lets maintained packages adopt the runtime API
without requiring every package to change its public values immediately.

Resource types not yet represented by the API remain under direct `bb-common` management.
An application must not use both mechanisms to manage the same feature. Overlapping
`bb-common` keys may be deprecated only after the replacement API reaches beta and
supported package migrations are available.

## Ownership transition

Migration from `Direct` to `EmittedCR` is an explicit package upgrade operation. It must
ensure that:

1. equivalent controller-managed protections are ready before Helm deletes directly
   rendered protections;
2. externally reachable routes are never left without requested authentication or
   authorization;
3. the controller does not forcibly adopt Helm-managed resources;
4. matching resource names do not imply permission to transfer ownership;
5. rollback restores direct protections before deleting controller-managed protections;
6. Flux drift detection does not treat expected controller changes as unauthorized
   drift.

Where an ownership change cannot be proven safe in one Helm operation, migration uses
two releases:

```text
Release N:
  Direct resources remain authoritative.
  The ApplicationIntegration runs in observe-only mode and reports equivalence.

Release N+1:
  Controller-managed protections become authoritative.
  Direct resources are removed only after controller readiness is confirmed.
```

Observe-only mode never creates externally reachable routes or claims ownership of
enforcement resources. It compares intended and existing behavior and reports conditions
needed to approve the next migration step.

## API evolution

The API follows Kubernetes compatibility conventions:

- `v1alpha1` may change as conformance and migration experience is gathered;
- storage uses one hub version and conversion webhooks before a second served version is
  introduced;
- `v1beta1` fields are preserved for at least three Big Bang minor releases after a
  replacement is introduced;
- `v1` fields are not removed or semantically weakened within the same major API version;
- new optional fields and new condition reasons may be added compatibly;
- security defaults may become stricter in a minor release when required to remediate a
  vulnerability, with an upgrade notice and migration guidance;
- schemas are structural, reject unknown fields, and use CEL validation for invariants
  that OpenAPI cannot express;
- controller conformance tests are versioned with the CRD and run against every supported
  integration class.

Graduation from alpha to beta requires:

- successful use by at least one team-maintained application package, one supported
  add-on, and one mission application not deployed by the Big Bang umbrella;
- sidecar and ambient mesh coverage;
- external OIDC and Authservice proxy coverage;
- upgrade testing across two consecutive Big Bang releases;
- published conformance tests and generated-resource ownership tests;
- documented behavior when optional platform backends are disabled;
- a reviewed migration path from the overlapping `bb-common` values.

## Non-goals

The API does not:

- install or upgrade an application;
- replace Flux, Helm, Kustomize, Argo CD, or the Big Bang package catalog;
- expose arbitrary implementation-specific resources through a generic object field;
- configure application business authorization;
- provision cluster infrastructure, DNS, load balancers, certificates, databases, or
  object storage;
- replace native Gateway API for advanced traffic management;
- embed Kyverno or other policy-engine exceptions;
- claim that the underlying Kubernetes cluster is hardened or compliant.

## Consequences

Applications gain one deployment-tool-independent contract and one status object for
their platform integrations. Platform implementations can evolve without requiring every
application chart to change. Big Bang can apply secure defaults consistently to built-in
packages, catalog packages, and mission applications.

Big Bang must operate and secure a new controller, CRDs, conversion strategy, and
conformance suite. Reconciliation ownership must be coordinated carefully with Flux and
Helm. Some `bb-common` features will remain outside the API, and maintainers will support
both mechanisms during a multi-release migration.

Phased adoption reduces initial migration and controller-privilege risk, but temporarily
requires two rendering paths and equivalent conformance coverage for both. Each duplicated
feature must have a graduation gate, migration owner, and exit condition so that the
incubation path does not become an unplanned permanent compatibility burden.

The API deliberately favors a small portable contract over exposing every capability of
Istio, Prometheus Operator, or `bb-common`. Applications with advanced needs continue to
use native resources alongside the integration resource.

## Alternatives considered

### Continue using only `bb-common`

This retains a mature implementation but keeps platform integration bound to Helm render
time and provides no runtime application-integration status.

### Copy an existing application-intent API

Comparable industry tooling demonstrates the value of an application-intent resource,
but copying an existing API would also import assumptions about its platform and
delivery model. Big Bang must support optional identity, monitoring, policy, and mesh
packages, preserve Flux field ownership, and prefer Gateway API for portable ingress.

### Put integration fields under `packages.<name>`

This works for applications deployed by the Big Bang umbrella but excludes workloads
managed independently by mission teams or Argo CD. It also keeps runtime intent inside
the umbrella Helm release rather than representing it in the application namespace.

### Allow raw Kubernetes objects in the custom resource

This would make the API appear flexible while freezing implementation-specific schemas
inside the public contract. Native resources beside the custom resource provide the same
escape path with clearer ownership and validation.

## Delivery target

Initial availability of the alpha API and controller is targeted for Big Bang 5.0 in
FY27. Advancement through the adoption phases is governed by the security, conformance,
operational, and migration gates in this ADR rather than by the release number alone.

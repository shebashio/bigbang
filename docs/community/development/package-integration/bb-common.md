# `bb-common` Subchart Integration

The [`bb-common`](https://repo1.dso.mil/big-bang/product/packages/bb-common)
chart provides standardized resources for integrating packages with Big Bang's
security and networking features. Integrated packages consume `bb-common` as a
regular Helm subchart, which renders these resources directly and validates its
configuration against its own values schema.

## Prerequisites

- A [Big Bang project containing the upstream Helm chart](./upstream.md)
- bb-common added as a chart dependency in `Chart.yaml`

## What bb-common Provides

- **Istio Service Mesh** - Virtual services, sidecars, gateways
- **Network Policies** - Kubernetes network traffic control
- **Authorization Policies** - Service-to-service access control
- REGISTRY_ONLY mode and default-deny policies and other good defaults

## Integration Steps

### 1. Add bb-common Dependency

Add to your `Chart.yaml`:

```yaml
dependencies:
  - name: bb-common
    repository: oci://registry1.dso.mil/bigbang
    version: "x.x.x"
```

### 2. Service Mesh Integration

**See:** [bb-common Istio Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/istio.md) and [Routes Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/routes.md)

- Enable Istio sidecar injection on your namespace, not needed if deploying using Big Bang umbrella, i.e. `packages`
- Configure the package's `istio` and `routes` values beneath the `bb-common` dependency key.
- Do not add package templates that call the legacy `bb-common.*.render` library interfaces; the subchart renders its supported resources directly.

```yaml
bb-common:
  istio: {}
  routes: {}
```

### 3. Network Policies

**See:** [bb-common Network Policies Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/network-policies.md)

- Configure the `bb-common.networkPolicies` values section; the subchart renders the policies directly.
- Add custom policies via `ingress` and `egress` as needed

```yaml
bb-common:
  networkPolicies: {}
```

### 4. Authorization Policies

**See:** [bb-common Authorization Policies Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/authorization-policies.md)

- Configure authorization policies under `bb-common.istio.authorizationPolicies`.
- Set `bb-common.istio.authorizationPolicies.generateFromNetpol: true` to generate corresponding Istio `AuthorizationPolicy` resources from identity-bearing network-policy rules.
- Include identities in network-policy entries using the `service-account@namespace/pod` form when service-account authentication is required
- Add package-specific policies through `bb-common.istio.authorizationPolicies.custom`; use the bb-common documentation as the source of truth for supported fields.

### Umbrella compatibility

Package charts should expose the subchart-scoped values structure described
above. During the Big Bang 3.x package-by-package transition, the umbrella uses
its package integration metadata to send either the flat library-chart shape or
the nested subchart shape expected by each package. Do not model a new package's
standalone values API on the legacy flat or `istio.hardened` structures.

## Additional Resources

- [bb-common Main Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/tree/main/docs)
- [bb-common Resource Graph](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/resource-graph.md)

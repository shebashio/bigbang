# Big Bang Common Library Integration

The Big Bang Common Library ([bb-common](https://repo1.dso.mil/big-bang/product/packages/bb-common)) is a shared Helm chart that renders standardized security, networking, routing, and Istio resources for an application.

## Prerequisites

- A [Big Bang project containing the upstream Helm chart](./upstream.md)
- bb-common added as a chart dependency in `Chart.yaml`

## What bb-common Provides

- **Istio resources** — PeerAuthentication, Sidecar, ServiceEntry, AuthorizationPolicy, and ambient waypoint resources as configured
- **Routes** — inbound VirtualServices and controlled outbound service registration
- **Network policies** — default and application-specific Kubernetes NetworkPolicy resources
- **Authorization policies** — defaults, custom policies, and policies generated from supported network-policy peers

## Integration Steps

### 1. Add bb-common Dependency

Add to your `Chart.yaml`:

```yaml
dependencies:
  - name: bb-common
    repository: oci://registry1.dso.mil/bigbang
    version: "x.x.x"
```

Select and pin a released version from the [bb-common tags](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/tags), then run `helm dependency update chart` from the package repository root.

### 2. Service Mesh Integration

**See:** [bb-common Istio documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/istio/README.md) and [routes documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/routes/README.md)

- Enroll the namespace in the intended Istio data plane—sidecar or ambient—when installing the package independently. Big Bang supplies the appropriate namespace and package values for integrated deployments.
- Use `{{- include "bb-common.istio.render" . }}` to render the configured PeerAuthentication, Sidecar, ServiceEntry, and AuthorizationPolicy resources
- Use `{{- include "bb-common.routes.render" . }}` to render inbound and outbound routes
- Configure the package's `istio`, `networkPolicies`, and `routes` values following the current bb-common patterns

### 3. Network Policies

**See:** [bb-common network-policy documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/network-policies/README.md)

- Use `{{- include "bb-common.network-policies.render" . }}` in templates
- Configure `networkPolicies` values section
- Add custom policies via `ingress` and `egress` as needed

### 4. Authorization Policies

**See:** [bb-common authorization-policy documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/authorization-policies/README.md)

- Configure authorization policies under `istio.authorizationPolicies`
- Set `istio.authorizationPolicies.generateFromNetpol: true` to have `bb-common.network-policies.render` generate corresponding Istio `AuthorizationPolicy` resources from identity-bearing network-policy rules
- Include identities in network-policy entries using the `service-account@namespace/pod` form when service-account authentication is required
- Use `bb-common.istio.render` for default and custom Istio authorization policies, and add package-specific policies through `istio.authorizationPolicies.custom`; use the bb-common documentation as the source of truth for supported fields

### Umbrella Compatibility

Package charts should expose the current bb-common value structure described above. The Big Bang umbrella still accepts `istio.hardened` settings as a compatibility and global-hardening input, then translates those settings into current package values such as `istio.sidecar`, `istio.serviceEntries`, and `istio.authorizationPolicies`. Do not model a new package's standalone values API on the legacy `istio.hardened` structure.

## Additional Resources

- [bb-common Main Documentation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/tree/main/docs)
- [bb-common Integration Guide](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/INTEGRATION_GUIDE.md)
- [bb-common Resource Graph](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/RESOURCE_GRAPH.md)

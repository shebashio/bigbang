# BigBang Maintained Packages (`bb_maintained`)

The `bb_maintained` flag enables automatic BigBang integration for packages hosted under the [BigBang Maintained](https://repo1.dso.mil/big-bang/product/maintained) track.

## Overview

When `bb_maintained: true` is set on a package, BigBang automatically:

1. **Injects infrastructure values** - domain, istio, monitoring, networkPolicies
2. **Applies postRenderers** - from package-specific named Helm templates
3. **Enables dependencies** - istio, monitoring auto-added to dependsOn
4. **Configures namespace** - auto-enables istio injection label

## Usage

```yaml
packages:
  nxrm-ha:
    enabled: true
    bb_maintained: true  # Enable BigBang integration
    git:
      repo: https://repo1.dso.mil/big-bang/product/maintained/nxrm-ha.git
      path: "./chart"
      tag: "86.2.0-bb.0"
    values:
      # Your application-specific values here
```

## Auto-Injected Values

When `bb_maintained: true`, the following values are automatically injected into the package:

| Value | Source | Description |
|-------|--------|-------------|
| `domain` | `$.Values.domain` | BigBang domain for ingress |
| `openshift` | `$.Values.openshift` | OpenShift compatibility flag |
| `istio.enabled` | `$.Values.istiod.enabled` | Istio mesh enabled state |
| `istio.hardened.enabled` | Computed | Hardened istio mode |
| `istio.injection` | Package config | Sidecar injection setting |
| `istio.<pkg>.gateways` | Computed | Gateway configuration |
| `monitoring.enabled` | `$.Values.monitoring.enabled` | Monitoring enabled state |
| `monitoring.serviceMonitor.createMetricsUser` | `true` when monitoring enabled | Enables Prometheus authentication for metrics scraping |
| `monitoring.serviceMonitor.scheme` | `https` when istio+monitoring enabled | mTLS scheme for ServiceMonitor |
| `monitoring.serviceMonitor.tlsConfig` | Computed | mTLS certificates config when istio+monitoring enabled |
| `networkPolicies.enabled` | `$.Values.networkPolicies.enabled` | Network policies state |
| `networkPolicies.ingressLabels` | Computed | Gateway selector labels |
| `podAnnotations` | Computed | Istio proxy annotations |

### Monitoring Integration

When `monitoring.enabled: true`, BigBang automatically configures packages for Prometheus scraping:

- **`createMetricsUser: true`** - For packages like Nexus that require authentication, this creates a dedicated metrics user allowing Prometheus to authenticate and scrape metrics without 403 errors
- **mTLS configuration** - When istio is also enabled, the ServiceMonitor is configured with proper mTLS settings (scheme: https, tlsConfig with certificates)

This provides **addon parity** - bb_maintained packages receive the same automatic monitoring configuration as built-in BigBang addons.

### Value Precedence

BigBang infrastructure values **override** user-provided values for the keys listed above. This ensures proper integration - for example, `istio.enabled` must match the global setting to avoid mesh communication issues.

User values for application-specific settings (not in the list above) are preserved.

## PostRenderers

BigBang can apply package-specific postRenderers using native Helm templates defined in `chart/templates/package/_postrenderers.tpl`.

### Package Name Lookup Order

The package name for postRenderers lookup is determined in order:

1. **Git repo name** - extracted from `git.repo` URL (e.g., `nxrm-ha` from `https://.../nxrm-ha.git`)
2. **Helm repo chart name** - from `helmRepo.chartName`
3. **Package key name** - the key used in the packages map

### PostRenderers Template Format

PostRenderers are defined as named Helm templates:

```yaml
# chart/templates/package/_postrenderers.tpl

{{- define "bb.postrenderers.nxrm-ha" -}}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /metadata/labels/app
            value: {{ . }}
        target:
          kind: Service
          name: {{ . }}
{{- end -}}
```

The package name is passed as the template context (`.`), enabling native Helm templating instead of custom placeholder replacement.

### PostRenderers Merge Behavior

When both default postRenderers (from template) and user postRenderers are defined, they are **merged in order**:

1. **Default postRenderers** - from named template, applied first
2. **User postRenderers** - appended after defaults

**Example:**

```yaml
# User configuration
packages:
  nxrm-ha:
    bb_maintained: true
    postRenderers:
      - kustomize:
          patches:
            - patch: |
                - op: add
                  path: /metadata/labels/custom
                  value: my-value
              target:
                kind: ConfigMap
                name: my-config
```

**Resulting HelmRelease:**

```yaml
spec:
  postRenderers:
    # Default postRenderers (from bb.postrenderers.nxrm-ha template)
    - kustomize:
        patches:
          - patch: |
              - op: add
                path: /metadata/labels/app
                value: nxrm-ha
            target:
              kind: Service
              name: nxrm-ha
    # User postRenderers - appended after
    - kustomize:
        patches:
          - patch: |
              - op: add
                path: /metadata/labels/custom
                value: my-value
            target:
              kind: ConfigMap
              name: my-config
```

This allows users to add additional patches without overriding the default BigBang integration patches.

## Auto-Enabled Dependencies

When `bb_maintained: true`, the HelmRelease automatically depends on:

| Dependency | Condition |
|------------|-----------|
| `istiod` | When `istiod.enabled: true` |
| `monitoring` | When `monitoring.enabled: true` |
| `gatekeeper` | When `gatekeeper.enabled: true` |
| `kyverno-policies` | When `kyvernoPolicies.enabled: true` |

## Namespace Configuration

When `bb_maintained: true` and istio is enabled, the package namespace automatically gets the `istio-injection: enabled` label (unless explicitly set otherwise).

## Example: Full Configuration

```yaml
packages:
  my-nexus:
    enabled: true
    bb_maintained: true
    git:
      repo: https://repo1.dso.mil/big-bang/product/maintained/nxrm-ha.git
      path: "./chart"
      tag: "86.2.0-bb.0"
    ingress:
      gateway: "public"
    values:
      # Application-specific values
      nexus:
        replicas: 3
      persistence:
        size: 100Gi
    # Optional: additional user postRenderers (appended to defaults)
    postRenderers:
      - kustomize:
          patches:
            - patch: |
                - op: add
                  path: /metadata/annotations/custom
                  value: my-value
              target:
                kind: ConfigMap
                name: my-nexus-config
```

## When to Use

Use `bb_maintained: true` for packages from the [BigBang Maintained track](https://repo1.dso.mil/big-bang/product/maintained) that have BigBang integration templates (istio, network policies, monitoring, etc.).

Do **not** use for:
- Third-party charts without BigBang integration
- Packages that don't need istio/monitoring/networkPolicies integration
- Custom applications that manage their own infrastructure config

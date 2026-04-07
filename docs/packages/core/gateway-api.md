# Gateway API

## Overview

[Gateway API](https://gateway-api.sigs.k8s.io/) is a collection of Kubernetes Custom Resource Definitions (CRDs) that provide an expressive, extensible, and role-oriented approach to defining traffic routing and network policies. It is the successor to the Kubernetes Ingress API and provides a more powerful and flexible way to configure ingress, egress, and service-to-service traffic.

Gateway API is a core dependency for Istio ambient mode and provides the standard API for configuring traffic management in modern Kubernetes environments.

```mermaid
flowchart TD
  subgraph "Gateway API CRDs"
    GC[GatewayClass] --> G[Gateway]
    G --> HR[HTTPRoute]
    G --> TR[TCPRoute]
    G --> GR[GRPCRoute]
  end

  subgraph "Traffic Flow"
    Client --> G
    HR --> Service1[Service A]
    TR --> Service2[Service B]
    GR --> Service3[Service C]
  end
```

## Big Bang Touchpoints

### Licensing

Gateway API is open source, licensed under the [Apache License 2.0](https://github.com/kubernetes-sigs/gateway-api/blob/main/LICENSE).

### Installation

Gateway API CRDs are installed into the `kube-system` namespace. The package can be enabled explicitly or is automatically enabled when `ambient: true` is set in Big Bang values:

```yaml
# Explicit enable
gatewayAPI:
  enabled: true

# Or via ambient mode (auto-enables gateway-api)
ambient: true
```

### Storage

Gateway API installs CRDs only and does not require any persistent storage.

### UI

Gateway API does not have a UI. Configuration is managed via kubectl and the Gateway API CRDs.

### Logging

Gateway API CRD controller logs are captured by the cluster's logging collector (Alloy or Fluentbit) and shipped to your configured logging backend.

### Health Checks

Standard Kubernetes readiness and liveness probes are configured for the Gateway API controller.

### Dependent Packages

Gateway API has no required dependencies within Big Bang. However, it is typically used alongside:

- **Istio** (istiod, istio-gateway): Uses Gateway API for traffic management when ambient mode is enabled
- **ztunnel**: Works with Gateway API for L4 traffic handling in ambient mode

### Configuration

Values can be passed through to the Gateway API chart:

```yaml
gatewayAPI:
  enabled: true
  values:
    # Upstream chart values go here
```

# Running Mission Applications in Big Bang with Istio Ambient Mode

[[_TOC_]]

## Overview

Big Bang enables Istio Ambient Mode for all integrated packages by setting `istio.ambient.enabled` to `true`. When enabled, Big Bang deploys the required ambient infrastructure and labels Big Bang-managed package namespaces with `istio.io/dataplane-mode: ambient`.

Mission applications and external Helm charts can still require additional work depending on how they are deployed and whether their chart has been integrated with [bb-common](../community/development/package-integration/bb-common.md). This document covers the expected paths for:

- A package deployed through the Big Bang `packages` key that has not been integrated with `bb-common`.
- A completely external Helm chart deployed outside of the Big Bang `packages` key.
- A mission application that must run in Istio sidecar mode while the rest of the environment uses Ambient Mode.

Where possible, prefer integrating the chart with [bb-common](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/INTEGRATION_GUIDE.md). The common library keeps service mesh, network policy, and authorization policy behavior aligned with Big Bang defaults and reduces the number of hand-maintained manifests required by operators. It also provides additional functionality needed for a given package to work properly in Ambient Mode.

> [!NOTE]
> The additional resources described in this article are limited to what is needed for an application to work in Ambient Mode, or to work in Sidecar Mode when the rest of the environment is running in Ambient Mode. A given package may still need other network policies, authorization policies, or package-specific configuration to function fully; those requirements are outside the scope of this article.

## Before You Start

Confirm the ambient control plane is enabled:

```yaml
istio:
  ambient:
    enabled: true
```

Review the following existing documentation before choosing an integration path:

- [Configuring Istio Ambient Mode in Big Bang](./ambient.md)
- [Extra Package Deployment](../installation/environments/extra-package-deployment.md)
- [Bb-Common Integration](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/INTEGRATION_GUIDE.md)

## Additional Network Policies/Network Policy Changes

### Allowing HBone Traffic

The following table illustrates when the addition of TCP Port 15008 (HBONE) traffic is required:

| Source | Destination | HBONE Required |
| ------- | ---------- | -------------- |
| Ambient | Ambient | Ingress and Egress |
| Ambient | Sidecar | Egress Only |
| Sidecar | Ambient | Ingress Only |

Original:

```
```

Updated:

```
```

> [!NOTE]
> If the application doesn't communicate with anything in any other namepsace and is in Sidecar Mode this is not needed.

### Allowing Kubelet Traffic

When a package is in Ambient Mode it will also require an additional network policy to allow traffic from the Kubelet for health and readiness probes to continue functioning as expected:

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-allow-kubelet-healthprobes
spec:
  podSelector:
    matchLabels:
      kubernetes.io/metadata.name: <Update with Package Namespace>
  ingress:
    - from:
      - ipBlock:
          cidr: 169.254.7.127/32
```

For additional information on the above listed network policies please refer to [Istio's Ambient and Kubernetes Network Policy Documentation](https://istio.io/latest/docs/ambient/usage/networkpolicy/).

## Authorization Policies

Since network policies behave a bit differently in Ambient Mode, authorization policies are now enabled by default with its behavior explicitly set to deny all traffic not otherwise allowed. This means every application will need an authorization policy that allows all traffic within its own namespace at a bare minimum:

```
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: default-authz-allow-all-in-ns
  namespace: <Update with Package Namespace>
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces:
        - <Update with Package Namespace>
```

### Prometheus Ingress

Another common authorization policy that may be required would be to allow prometheus access to an application's service monitor

```
```

### Istio Gateway Ingress

If the application allows traffic to it from an Istio Ingress Gateway the following authorization policy may also be needed:

```
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-gateway-authz-policy
  namespace: kiali
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces:
        - istio-gateway
        principals:
        - cluster.local/ns/istio-gateway/sa/public-ingressgateway-ingressgateway-service-account
  selector:
    matchLabels:
      app.kubernetes.io/name: kiali
```

## Namespace Labels



## Extra Package Deployment Using Packages Key

Use this path only when the chart cannot be modified to consume `bb-common`. Operators must explicitly provide the namespace labels, network policies, and mesh resources that `bb-common` would normally help generate.


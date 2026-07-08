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

### Allowing HBONE Traffic

The following table illustrates when the addition of TCP Port 15008 (HBONE) traffic is required:

| Source | Destination | HBONE Required |
| ------- | ---------- | -------------- |
| Ambient | Ambient | Ingress and Egress |
| Ambient | Sidecar | Egress Only |
| Sidecar | Ambient | Ingress Only |

Add TCP port 15008 in addition to the original application port in case services outside the mesh need to communicate with the application.

Original:

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-hbone-from-public-ingressgateway
  namespace: parabol
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: istio-gateway
      podSelector:
        matchLabels:
          app.kubernetes.io/name: public-ingressgateway
          istio: ingressgateway
    ports:
    - port: 3000
      protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/name: parabol
      app.kubernetes.io/component: webserver
  policyTypes:
  - Ingress
```

Updated:

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-hbone-from-public-ingressgateway
  namespace: parabol
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: istio-gateway
      podSelector:
        matchLabels:
          app.kubernetes.io/name: public-ingressgateway
          istio: ingressgateway
    ports:
    - port: 3000
      protocol: TCP
    - port: 15008
      protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/name: parabol
      app.kubernetes.io/component: webserver
  policyTypes:
  - Ingress
```

> [!NOTE]
> If the application doesn't communicate with anything in any other namespace and is in Sidecar Mode this is not needed.

### Allowing Kubelet Traffic

When a package is in ambient mode, it also requires an additional network policy to allow traffic from the kubelet so health and readiness probes continue functioning as expected.

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

Since network policies behave differently in Ambient Mode, authorization policies are enabled by default and deny traffic that is not otherwise allowed. At a minimum, every application needs an authorization policy that allows traffic within its own namespace.

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

It is also recommended to have an explicit deny-all authorization policy as shown below:

```
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: default-authz-allow-nothing
  namespace: <Update with Package Namespace>
spec: {}
```

### Prometheus Ingress

Another common authorization policy allows Prometheus to access an application’s ServiceMonitor:

```
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-ingress-to-metrics-from-ns-monitoring-with-identity-monitoring-monitoring-kube-prometheus
  namespace: <>
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/monitoring/sa/monitoring-monitoring-kube-prometheus
    to:
    - operation:
        ports:
        - <Update with Appropriate Port>
  selector:
    matchLabels:
      <Update with Appropriate Pod Labels>
```

### Istio Gateway Ingress

If the application allows traffic from an Istio ingress gateway, the following authorization policy may also be needed:

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
      <Update with Appropriate Pod Labels>
```

> [!NOTE]
> You may need to update the principal accordingly if using a non-default gateway.

## Namespace Labels

To label an application for Ambient Mode, use the following namespace label instead of the typical sidecar injection label:

```
istio.io/dataplane-mode: ambient
```

## Extra Package Deployment Using Packages Key

Use this path only when the chart cannot be modified to consume `bb-common`. Operators must explicitly provide the namespace labels, network policies, and mesh resources that `bb-common` would normally help generate.

The following example shows how to deploy the `Parabol` community package in a test environment via the `packages` key:

```
packages:
  parabol:
    enabled: true
    namespace:
      name: parabol
    helmRelease:
      namespace: "bigbang"
    sourceType: "git"
    git:
      repo: https://repo1.dso.mil/big-bang/product/community/parabol.git
      path: "./chart"
      branch: "main"
    values:
      global:
        imageRegistry:
          host: registry1.dso.mil
          imagePullSecrets:
            - name: private-registry
      networkPolicies:
        enabled: true
      services:
        redis:
          localStorage:
            enabled: true
        postgres:
          localStorage:
            enabled: true
            volumeSize: 10Gi
        parabol:
          localStorage:
            enabled: true
            volumeSize: 1Gi
            awsEbs: false
            storageClassName: "local-path"
            accessModes:
            - ReadWriteOnce
      parabolDeployment:
        env:
          serverId: 1
          authGooleDisabled: false
        readinessProbe:
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
          successThreshold: 1
          httpGet:
            path: /manifest.json
            port: 3000
```

The following additional network policies and authorization policies were also needed to allow the application to function properly:

```yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-kubelet-healthprobes
  namespace: parabol
spec:
  podSelector:
    matchLabels:
      kubernetes.io/metadata.name: parabol
  ingress:
    - from:
      - ipBlock:
          cidr: 169.254.7.127/32
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-postgresql-metrics-from-prometheus
  namespace: parabol
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
      podSelector:
        matchLabels:
          app.kubernetes.io/name: prometheus
    ports:
    - port: 9187
      protocol: TCP
    - port: 15008
      protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/component: postgres
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-redis-metrics-from-prometheus
  namespace: parabol
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
      podSelector:
        matchLabels:
          app.kubernetes.io/name: prometheus
    ports:
    - port: 9121
      protocol: TCP
    - port: 15008
      protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/component: redis
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-from-public-ingressgateway
  namespace: parabol
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: istio-gateway
      podSelector:
        matchLabels:
          app.kubernetes.io/name: public-ingressgateway
          istio: ingressgateway
    ports:
    - port: 3000
      protocol: TCP
    - port: 15008
      protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/name: parabol
      app.kubernetes.io/component: webserver
  policyTypes:
  - Ingress
```

```yaml
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: default-authz-allow-all-in-ns
  namespace: parabol
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces:
        - parabol
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-ingress-to-postgresql-metrics-from-ns-monitoring-with-identity-monitoring-monitoring-kube-prometheus
  namespace: parabol
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/monitoring/sa/monitoring-monitoring-kube-prometheus
    to:
    - operation:
        ports:
        - "9187"
  selector:
    matchLabels:
      app.kubernetes.io/component: postgres
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-ingress-to-redis-metrics-from-ns-monitoring-with-identity-monitoring-monitoring-kube-prometheus
  namespace: parabol
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/monitoring/sa/monitoring-monitoring-kube-prometheus
    to:
    - operation:
        ports:
        - "9121"
  selector:
    matchLabels:
      app.kubernetes.io/component: redis
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: parabol-public-ingressgateway-authz-policy
  namespace: parabol
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
      app.kubernetes.io/name: parabol
      app.kubernetes.io/component: webserver
```

## External Helm Chart Deployment Using ArgoCD in Ambient Mode

TODO: Add an Argo CD-based example for deploying an external Helm chart in ambient mode.

## Sidecar Mode Mission Application Using Argo CD

TODO: Add an Argo CD-based example for deploying a mission application in sidecar mode while ambient mode is enabled globally.
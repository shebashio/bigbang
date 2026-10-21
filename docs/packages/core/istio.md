# Istio Orchestration in Big Bang

This page retains umbrella-owned Istio package orchestration. Component-specific
configuration and operation guides now live with their package repositories:

- [Istio CRDs draft guide](https://repo1.dso.mil/big-bang/product/packages/istio-crds/-/blob/main/docs/overview.md)
- [Istiod draft guide](https://repo1.dso.mil/big-bang/product/packages/istiod/-/blob/main/docs/overview.md)
- [Istio CNI draft guide](https://repo1.dso.mil/big-bang/product/packages/istio-cni/-/blob/main/docs/overview.md)
- [Istio Gateway draft guide](https://repo1.dso.mil/big-bang/product/packages/istio-gateway/-/blob/main/docs/overview.md)

## Big Bang orchestration

With `packageConfiguration.version: v1`, configure the component packages as
`packages.istioCRDs`, `packages.istiod`, `packages.istioCNI`, and
`packages.istioGateway`. Legacy root-level names remain supported; see
[Package Management](../../concepts/package-management.md).

The umbrella creates the Istio namespaces, injects common images and values,
orders component releases, and manages ambient-mode enablement. Istiod depends on
Istio CRDs. Effective ambient mode (the global ambient flag or ztunnel) couples
Istio CNI, ztunnel, Gateway API, namespace enrollment, policy, and HBONE behavior.
See [Configuring Istio Ambient Mode](../../configuration/ambient.md) before changing
an existing environment.

Kiali, Grafana, Tempo, logging collectors, and monitoring are separately owned
integrations. Their enablement does not replace package-specific Istio validation.

## Scope

[Istio Egress Gateway](istio-egress-gateway.md) is outside this documentation
migration and remains an umbrella page.

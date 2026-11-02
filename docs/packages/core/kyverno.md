# Kyverno

## Overview

Kyverno is a policy engine designed for Kubernetes, where policies are managed as Kubernetes resources rather than with some domain-specific language. Kyverno policies can be managed by kubectl, git, and kustomize just like app deployments. Kyverno policies can validate, mutate, and generate Kubernetes resources plus ensure OCI image supply chain security, among other things.

## Big Bang Touch Points

### Architecture: 
- [How Kyverno works](https://kyverno.io/docs/introduction/#how-kyverno-works)

### Storage

Data from Kyverno is not stored by the app directly, it is stored as objects in the Kubernetes API.

### Istio Configuration

For a k3d development environment, a load-balancer workload in `istio-system`
may need an exception to `restrict-external-ips`. Use the CEL-based exception
shape shown below in an environment override. This exception is limited to
that policy and workload; it does not change the allowed image registries.
Review the [4.0 Kyverno policies migration guide](../../migration/migrating-kyverno-policies-for-bb4.0.md)
when converting existing exclusions or exceptions.

```yaml
packages:
  kyvernoPolicies:
    values:
      additionalPolicyExceptions:
        k3d-load-balancer:
          spec:
            policyRefs:
              - name: restrict-external-ips
                kind: ValidatingPolicy
            matchConditions:
              - name: k3d-load-balancer
                expression: >-
                  object.metadata.namespace == 'istio-system' &&
                  object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('svclb-')
```

## High Availability

High availability is accomplished by increasing the replicas in the values file of this helm chart. The recommended replica counts for HA is at least 3 which is enabled by default in BigBang chart.

```yaml
packages:
  kyverno:
    values:
      replicaCount: 3
```

## Kyverno Reporter

Kyverno Reporter is an optional component providing two main reporting functions: 
* Providing a metrics endpoint which can be used to observe in monitoring tools like Grafana.
* Reporting Kyverno policy violations to various configurable `targets`, including Grafana Loki, Elasticsearch, Slack, Discord or MS Teams.


```yaml
packages:
  kyvernoReporter:
    enabled: true
```

### Kyverno Reporter UI
While not yet officially supported by BigBang the Kyverno Reporter can be useful for inspecting policy results when other tools like Grafana are not available or in debugging scenarios.
```yaml
packages:
  kyvernoReporter:
    enabled: true

    values:
      global:
        plugins:
          kyverno:
            enabled: true

      ui:
        enabled: true

      kyvernoPlugin:
        enabled: true
```

## Single Sign on (SSO)

None. This service doesn't have a web interface.

## Licencing

[Apache 2.0 License](https://github.com/kyverno/kyverno/blob/main/LICENSE)

## Dependencies

`kyverno` is a dependency of `kyvernoPolicies`. KyvernoPolicies is a collection of Kyverno security and best-practice policies for Kyverno

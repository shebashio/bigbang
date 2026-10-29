# Using Network Policies in Big Bang

> **ℹ️ NOTE:** For package developers integrating network policies, see the [`bb-common` Subchart Integration](../community/development/package-integration/bb-common.md) guide, which consolidates service mesh, network-policy, and authorization-policy documentation.

## What are Network Policies

Kubernetes allows Big Bang operators to utilize [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) to control the network traffic into or out of the various pods of a Kubernetes cluster. These network policies allow you to restrict incoming and outgoing traffic to or from a given set of pods using selectors. [Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) allow you to select which pods a given networkPolicy will apply to. 

Network Policies are added as needed to supplement other good security practices; such as proper usage of TLS, only exposing necessary ports, and using other standard controls. However, Network Policies allow you to express additional control over what can connect to the pods in your cluster from outside; which pods in your kubernetes cluster can speak to each other internally; and which things those pods can initiate connections to outside of the cluster.

## Package Types and Support Levels

The mechanisms described in this document are natively available for:

- all bigbang core packages (such as kyverno, monitoring, istio, etc)
- all bigbang supported addon packages (such as minio, etc)
- select community supported addons (jira, confluence)

For the purposes of this document, "customer defined package" and "community supported package" may be used interchangably and the techniques for one will apply equally to the other. However, customer defined packages will need to implement support for the networkpolicy control mechanism themselves if they want to make use of this functionality. See the [`bb-common` Subchart Integration](../community/development/package-integration/bb-common.md) guide for how to implement this functionality in a customer defined package.

## Enabling or Disabling Network Policies

Big Bang core and addon packages ship with network policies already configured.
The global `networkPolicies.enabled` setting enables the shared package policy
defaults. Those defaults are also enabled whenever ambient mode is effective,
even if the global flag is false. Ambient mode is effective when either
`istio.ambient.enabled` or `packages.ztunnel.enabled` is true; policy rendering
also supports ambient authorization-policy generation. Package-level values can
override the generated setting. Community packages may use different controls;
check the package's documentation.

```yaml
# Ambient mode also enables the generated package policy defaults.
networkPolicies:
  enabled: true

# For an integrated package that consumes bb-common as a subchart, this will
# turn network policies on or off for that package. User-defined packages that
# consume bb-common as a subchart use the same nested values shape.
packages:
  monitoring:
    values:
      bb-common:
        networkPolicies:
          enabled: true
```

## Enabling Authorization Policies

AuthorizationPolicies are disabled globally by default. Enable them for
integrated packages with:

```yaml
authorizationPolicies:
  enabled: true
```

Ambient mode enables AuthorizationPolicies regardless of this value. A package
can override the generated setting beneath
`packages.<name>.values.istio.authorizationPolicies`, or beneath
`packages.<name>.values.bb-common.istio.authorizationPolicies` after migrating
`bb-common` to a regular subchart.

## Crafting and Delivering Additional Network Policies

Sometimes you will want to apply additional [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) to further isolate certain pods in your deployment. BigBang has adopted standardized mechanisms for crafting and deploying these Network Policies through the values provided to your BigBang core, supported addon or packages deployed with the big bang wrapper chart.

For packages that consume `bb-common` as a subchart, put `additionalPolicies`
under the package's `bb-common.networkPolicies` values. The following **umbrella
values** add an egress policy to the Monitoring package's Prometheus Pods:

```yaml
packages:
  monitoring:
    values:
      bb-common:
        networkPolicies:
          additionalPolicies:
            - name: example-prometheus-egress
              spec:
                podSelector:
                  matchLabels:
                    app: prometheus
                policyTypes:
                  - Egress
                egress:
                  - to:
                      - ipBlock:
                          cidr: 192.0.2.0/24
                    ports:
                      - protocol: TCP
                        port: 443
```

`192.0.2.0/24` is a documentation CIDR, not a working destination; replace it
with the actual permitted range. Verify that the selector matches the intended
Pods. Kubernetes combines allow rules from all policies selecting a Pod, so an
additional policy does not restrict traffic already allowed by another policy.
The list replaces any existing `additionalPolicies` list at this values path;
include existing entries that must be retained. In ambient mode, also configure
any required Istio authorization and egress routing for the destination.

User-defined packages own their internal values contract. When such a package
consumes `bb-common` as a subchart, use the same nested shape. Consult the
[Kubernetes NetworkPolicy documentation](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
and the package's configuration for selectors and supported policy options.

## References

* [Kubernetes Network Policies Documentation](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
* [Kubernetes Labels and Selectors Documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
* [Big Bang Developer Guide for Package Implementation](../community/development/develop-package.md)
* [`bb-common` Subchart Integration](../community/development/package-integration/bb-common.md)

For more information regarding the behavior of a specific core, supported addon or community supported package, you should always reference the documentation for the specific package in question. Information specific to any given package is outside the scope of this documentation.

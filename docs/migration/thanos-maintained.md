# Move Thanos to a custom package

Thanos is no longer a built-in Big Bang add-on. Remove `addons.thanos` from existing values and deploy it through the [extra package contract](../installation/environments/extra-package-deployment.md). The `packages.thanos` name remains available as a custom package, but its former add-on fields are not translated automatically.

The source below uses the existing package repository until its transfer to `big-bang/product/maintained` is complete. Update the URL and tag to a published maintained release when that project is available.

```yaml
packages:
  thanos:
    enabled: true
    namespace:
      name: thanos
    helmRelease:
      namespace: bigbang
    sourceType: git
    git:
      repo: https://repo1.dso.mil/big-bang/product/packages/thanos.git
      path: chart
      tag: 17.6.0-bb.1
    dependsOn:
      - name: monitoring
        namespace: bigbang
    values:
      monitoring:
        enabled: true
```

This preserves the HelmRelease name and namespace (`bigbang/thanos`), the Helm release name (`thanos`), and its target namespace. Review the rendered release and back up any object-store data before upgrading an existing installation.

Move former `addons.thanos.values` entries under `packages.thanos.values`. The former `addons.thanos.objectStorage`, `sso`, `ingress`, and `flux` shortcuts need explicit replacements:

| Former behavior | Configure after migration |
| --- | --- |
| Prometheus Thanos sidecar and discovery Service | `monitoring.values.upstream.prometheus.thanosService`, `thanosServiceMonitor`, and `prometheusSpec.thanos` |
| Prometheus object-store Secret | Create a Secret containing `objstore.yml` in `monitoring`, then set `monitoring.values.upstream.prometheus.prometheusSpec.thanos.objectStorageConfig.existingSecret` |
| Grafana Thanos datasource | Set `grafana.values.upstream.datasources` to the desired datasource list; include any existing datasources that must remain |
| Thanos ingress and SSO | Set Thanos chart `routes` and `istio` values, and configure `addons.authservice.chains.thanos` explicitly if needed |
| Thanos-specific Kyverno policy exceptions | Add the required exceptions under `kyvernoPolicies.values` for the deployment |
| Flux drift detection settings | Move them to `packages.thanos.flux` |

Keep object-store credentials in encrypted secret values. See the [Thanos chart values](https://repo1.dso.mil/big-bang/product/packages/thanos/-/blob/main/chart/values.yaml) and [Monitoring guide](../packages/core/monitoring.md) for the package-specific configuration.

# Move Thanos to a custom package

Thanos is no longer a built-in Big Bang add-on. Remove `addons.thanos` from existing values and deploy it through the [extra package contract](../installation/environments/extra-package-deployment.md). The `packages.thanos` name remains available as a custom package, but its former add-on fields are not translated automatically.

The source below uses the existing package repository until its transfer to `big-bang/product/maintained` is complete. Update the URL and tag to a published maintained release when that project is available.

For a render-tested starting point that includes Prometheus discovery and external object storage, use [thanos-values-example.yaml](thanos-values-example.yaml). It is **not** a production-ready values file: replace the endpoint, credentials, domain, and tag, and supply the object-store Secret before deploying. The short example below shows only the package contract.

The [Grafana overlay](thanos-grafana-overlay.yaml) switches the existing `prometheus` datasource UID to Thanos and keeps the Loki and Tempo datasources from this example. If your deployment enables other datasources, add them to its list before applying the overlay. The [object-store Secret example](monitoring-objstore-secret-example.yaml) shows the key Monitoring expects; replace and encrypt its credentials, and keep it aligned with Thanos's `upstream.objstoreConfig`. For sidecar-mode STRICT mTLS, also apply the [strict-mTLS overlay](thanos-strict-mtls-overlay.yaml).

For sidecar-mode SSO and the three former Thanos Kyverno policy entries, layer [thanos-sso-kyverno-overlay.yaml](thanos-sso-kyverno-overlay.yaml) on that example. Replace its OIDC client ID and secret and encrypt them before deployment. The overlay explicitly enables Authservice: `packages.thanos` no longer auto-enables it. Render both files in order with `helm template bigbang ./chart -f docs/migration/thanos-values-example.yaml -f docs/migration/thanos-sso-kyverno-overlay.yaml` to inspect the generated values Secrets.

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

Move former `addons.thanos.values` entries under `packages.thanos.values`. This carries only values explicitly supplied by the operator; it does not recreate the defaults previously injected by the umbrella chart. The former `addons.thanos.objectStorage`, `sso`, `ingress`, `strategy`, and `flux` shortcuts need explicit replacements:

| Former behavior | Configure after migration |
| --- | --- |
| Prometheus Thanos sidecar and discovery Service | Set `monitoring.values.upstream.prometheus.thanosService`, `thanosServiceMonitor`, and `prometheusSpec.thanos`; set `packages.thanos.values.upstream.query.stores` to the discovery Service. The base example also restores Thanos-to-Prometheus access under `monitoring.values.networkPolicies.ingress`. |
| Prometheus object-store Secret | Create `monitoring/monitoring-objstore-secret` with key `objstore.yml`, then set `monitoring.values.upstream.prometheus.prometheusSpec.thanos.objectStorageConfig.existingSecret`. Configure the same object store under `packages.thanos.values.upstream.objstoreConfig`. Use the linked Secret example with encrypted values or a secret manager. |
| Thanos store gateway and compactor | Set `packages.thanos.values.upstream.storegateway.enabled` and `compactor.enabled` explicitly when using object storage. The old `strategy` and object-storage-driven auto-enablement no longer apply. |
| Grafana Thanos datasource | Use the linked Grafana overlay to put Thanos at the existing `prometheus` UID and point it at `http://thanos-query.thanos.svc:9090`. It also adds Grafana-to-Thanos network-policy egress. **Include every other datasource you still need**: the list override is complete, not additive. |
| Thanos ingress and SSO | Set `packages.thanos.values.routes.inbound.query-frontend` for ingress. Set `addons.authservice.enabled: true` and configure `addons.authservice.chains.thanos` with the matching host, client ID, secret, and OIDC endpoints. The linked overlay restores the sidecar-mode query-frontend label and Authservice egress. Ambient mode instead needs route-level `authservice` settings and the Thanos waypoint/service labels; it must be tested separately. |
| Strict-mTLS ServiceMonitor | Use the linked strict-mTLS overlay only in sidecar-mode STRICT mTLS. It restores the Thanos ServiceMonitor HTTPS/certificate post-renderer and the Prometheus Thanos sidecar certificate mount; Monitoring already creates the shared `istio-certs` volume in this mode. |
| Network policies and hardened Istio egress | Restore Thanos-to-Prometheus, Grafana-to-Thanos, gateway-to-query-frontend, authservice, MinIO, and S3 access as applicable in the package and peer-package `networkPolicies` values. The generic package does not generate these Thanos-specific cross-package rules or the old object-store ServiceEntry. |
| MinIO | Set `packages.thanos.values.minio.enabled` and its tenant values explicitly. The old scalable-strategy auto-enable and test defaults are not carried over. |
| Thanos-specific Kyverno policy entries | The linked overlay restores the compactor exclusion from `disallow-auto-mount-service-account-token`, adds `thanos` to `update-automountserviceaccounttokens-default`, and restores the Thanos pod allow/deny rules in `update-automountserviceaccounttokens`. Big Bang's overlay merge appends the first and third lists; this MR also makes the default-ServiceAccount namespace list additive so other namespaces are retained. |
| Registry credentials, test settings, and Flux | Restore any `image` / `upgradeJob.image`, `bbtests`, `packages.thanos.flux`, and `packages.thanos.postRenderers` settings that the old defaults supplied or that you previously customized. |

The generic package path provides the HelmRelease, source, values Secret, bb-common defaults, and standard dependencies. It does **not** create resources or overrides in Monitoring, Grafana, Authservice, or Kyverno. Check the rendered HelmRelease and values Secrets before applying the migration. Existing installations also need a test of Flux resource adoption and data retention in a disposable cluster; a template render cannot establish upgrade safety.

Keep object-store credentials in encrypted secret values. See the [Thanos chart values](https://repo1.dso.mil/big-bang/product/packages/thanos/-/blob/main/chart/values.yaml) and [Monitoring guide](../packages/core/monitoring.md) for the package-specific configuration.

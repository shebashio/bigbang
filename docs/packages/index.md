# Integrated Packages

This catalog lists the packages rendered directly by the Big Bang umbrella chart. `chart/values.yaml` supplies the release-pinned package source.

Configure built-in packages under `packages.<name>` when using `packageConfiguration.version: v1`. See [Package Management](../concepts/package-management.md) for the configuration model and [Categorization](categorization.md) for package roles and stack relationships.

The integration guide covers Big Bang-specific behavior. The package repository owns packaged chart values, implementation details, and its changelog.

## Core packages

Core packages provide the platform capabilities that other packages commonly depend on.

| Package | Canonical configuration | Big Bang integration | Package source |
| --- | --- | --- | --- |
| Alloy | `packages.alloy` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/alloy/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/alloy) |
| cert-manager | `packages.certManager` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/cert-manager/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/cert-manager) |
| ECK Operator | `packages.eckOperator` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/eck-operator/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/eck-operator) |
| Elasticsearch Kibana | `packages.elasticsearchKibana` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana) |
| Fluent Bit | `packages.fluentbit` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/fluentbit/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/fluentbit) |
| Gatekeeper | `packages.gatekeeper` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/policy/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/policy) |
| Gateway API | `packages.gatewayAPI` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/gateway-api/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/gateway-api) |
| Grafana | `packages.grafana` | [Guide](core/monitoring.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/grafana) |
| Istio CNI | `packages.istioCNI` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/istio-cni/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/istio-cni) |
| Istio CRDs | `packages.istioCRDs` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/istio-crds/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/istio-crds) |
| Istio Gateway | `packages.istioGateway` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/istio-gateway/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/istio-gateway) |
| Istiod | `packages.istiod` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/istiod/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/istiod) |
| Kiali | `packages.kiali` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/kiali/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/kiali) |
| Kyverno | `packages.kyverno` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/kyverno/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/kyverno) |
| Kyverno Policies | `packages.kyvernoPolicies` | [Guide](core/kyverno.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies) |
| Kyverno Reporter | `packages.kyvernoReporter` | [Guide](core/kyverno.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter) |
| Loki | `packages.loki` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/loki/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/loki) |
| Monitoring | `packages.monitoring` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/monitoring/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/monitoring) |
| NeuVector | `packages.neuvector` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/neuvector/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/neuvector) |
| Prometheus Operator CRDs | `packages.prometheusOperatorCRDs` | [Guide](core/monitoring.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/prometheus-operator-crds) |
| Renovate | `packages.renovate` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/renovate/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/renovate) |
| Tempo | `packages.tempo` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/tempo/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/tempo) |
| Twistlock | `packages.twistlock` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/twistlock/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/twistlock) |
| Ztunnel | `packages.ztunnel` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/ztunnel/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/ztunnel) |

## Add-on packages

Add-on packages provide optional platform and application capabilities.

| Package | Canonical configuration | Big Bang integration | Package source |
| --- | --- | --- | --- |
| Anchore Enterprise | `packages.anchoreEnterprise` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/anchore-enterprise/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/anchore-enterprise) |
| Argo CD | `packages.argocd` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/argocd/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/argocd) |
| Authservice | `packages.authservice` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/authservice/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/authservice) |
| External Secrets | `packages.externalSecrets` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/external-secrets/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/external-secrets) |
| Fortify | `packages.fortify` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/fortify/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/fortify) |
| GitLab | `packages.gitlab` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/gitlab/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/gitlab) |
| GitLab Runner | `packages.gitlabRunner` | [Guide](addons/gitlab.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/gitlab-runner) |
| Harbor | `packages.harbor` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/harbor/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/harbor) |
| Headlamp | `packages.headlamp` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/headlamp/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/headlamp) |
| Keycloak | `packages.keycloak` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/keycloak/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/keycloak) |
| Mattermost | `packages.mattermost` | [Guide](addons/mattermost.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/mattermost) |
| Mattermost Operator | `packages.mattermostOperator` | [Guide](addons/mattermost.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/mattermost-operator) |
| Metrics Server | `packages.metricsServer` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/metrics-server/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/metrics-server) |
| Mimir | `packages.mimir` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/mimir/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/mimir) |
| MinIO | `packages.minio` | [Guide](addons/minio.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/minio) |
| MinIO Operator | `packages.minioOperator` | [Guide](addons/minio.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/minio-operator) |
| SonarQube | `packages.sonarqube` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/sonarqube/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/sonarqube) |
| Thanos | `packages.thanos` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/thanos/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/thanos) |
| Vault | `packages.vault` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/vault/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/vault) |
| Velero | `packages.velero` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/velero/-/blob/main/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/velero) |

## Other package collections

- [Maintained packages](https://repo1.dso.mil/groups/big-bang/product/maintained) are maintained and tested independently but are not rendered directly by the umbrella chart.
- [Community packages](https://repo1.dso.mil/groups/big-bang/product/community) are owned by community maintainers and are not supported as built-in integrations.
- Use [Extra Package Deployment](../installation/environments/extra-package-deployment.md) to deploy a package that is not integrated directly.

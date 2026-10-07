# Integrated Packages

This catalog lists the packages rendered directly by the Big Bang umbrella chart. `chart/values.yaml` supplies the release-pinned package source.

Configure built-in packages under `packages.<name>` when using `packageConfiguration.version: v1`. See [Package Management](../concepts/package-management.md) for the configuration model and [Categorization](categorization.md) for package roles and stack relationships.

The integration guide covers Big Bang-specific behavior. The package repository owns packaged chart values, implementation details, and its changelog.

## Core packages

Core packages provide the platform capabilities that other packages commonly depend on.

| Package | Canonical configuration | Big Bang integration | Package source |
| --- | --- | --- | --- |
| Alloy | `packages.alloy` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/alloy/-/blob/976e0e3836d15cc976e5e5f73332f42e0f34cf75/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/alloy) |
| cert-manager | `packages.certManager` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/cert-manager/-/blob/2497ca2c4bb00125fea7db7d78d784e64149290c/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/cert-manager) |
| ECK Operator | `packages.eckOperator` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/eck-operator/-/blob/64260d2473a1d320f4959bcaeb2884bdd5bfa9b4/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/eck-operator) |
| Elasticsearch Kibana | `packages.elasticsearchKibana` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana/-/blob/76bea319822232afab2c22505e83a66e9ca2d03d/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana) |
| Fluent Bit | `packages.fluentbit` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/fluentbit/-/blob/d15f1b1c614090342e8702832fbe09b3bb99f431/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/fluentbit) |
| Gatekeeper | `packages.gatekeeper` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/policy/-/blob/e07223e92cf47a5bb5efe293a7ea71f75187ed0a/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/policy) |
| Gateway API | `packages.gatewayAPI` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/gateway-api/-/blob/cd988dc3a9a64d05899783850f8f9e5c285edacc/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/gateway-api) |
| Grafana | `packages.grafana` | [Guide](core/monitoring.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/grafana) |
| Istio CNI | `packages.istioCNI` | [Guide](core/istio.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/istio-cni) |
| Istio CRDs | `packages.istioCRDs` | [Guide](core/istio.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/istio-crds) |
| Istio Gateway | `packages.istioGateway` | [Guide](core/istio.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/istio-gateway) |
| Istiod | `packages.istiod` | [Guide](core/istio.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/istiod) |
| Kiali | `packages.kiali` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/kiali/-/blob/9216b468197153547711ff738fd4bddc4acadd75/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/kiali) |
| Kyverno | `packages.kyverno` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/kyverno/-/blob/44642cd53a556731f091d4560d5a0ca2788d9fe4/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/kyverno) |
| Kyverno Policies | `packages.kyvernoPolicies` | [Guide](core/kyverno.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies) |
| Kyverno Reporter | `packages.kyvernoReporter` | [Guide](core/kyverno.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/kyverno-reporter) |
| Loki | `packages.loki` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/loki/-/blob/ad59e86c815184264ab157daea04ef676c197ac9/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/loki) |
| Monitoring | `packages.monitoring` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/monitoring/-/blob/8d24ee480e09429d06568f0d2484d72de5343afb/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/monitoring) |
| NeuVector | `packages.neuvector` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/neuvector/-/blob/137a68d96f91d228f0be25e09704b13f301e50d5/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/neuvector) |
| Prometheus Operator CRDs | `packages.prometheusOperatorCRDs` | [Guide](core/monitoring.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/prometheus-operator-crds) |
| Renovate | `packages.renovate` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/renovate/-/blob/2c8f1170/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/renovate) |
| Tempo | `packages.tempo` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/tempo/-/blob/997f43387422fc07278704f381d2c37eb09f6dac/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/tempo) |
| Twistlock | `packages.twistlock` | [Draft guide](https://repo1.dso.mil/big-bang/product/packages/twistlock/-/blob/4381fcf990611782455c0d5814d774726499b0e2/docs/overview.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/twistlock) |
| Ztunnel | `packages.ztunnel` | [Guide](core/ztunnel.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/ztunnel) |
## Add-on packages

Add-on packages provide optional platform and application capabilities.

| Package | Canonical configuration | Big Bang integration | Package source |
| --- | --- | --- | --- |
| Anchore Enterprise | `packages.anchoreEnterprise` | [Guide](addons/anchore.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/anchore-enterprise) |
| Argo CD | `packages.argocd` | [Guide](addons/argocd.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/argocd) |
| Authservice | `packages.authservice` | [Guide](addons/authservice.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/authservice) |
| External Secrets | `packages.externalSecrets` | [Guide](addons/external-secrets-operator.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/external-secrets) |
| Fortify | `packages.fortify` | [Guide](addons/fortify.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/fortify) |
| GitLab | `packages.gitlab` | [Guide](addons/gitlab.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/gitlab) |
| GitLab Runner | `packages.gitlabRunner` | [Guide](addons/gitlab.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/gitlab-runner) |
| Harbor | `packages.harbor` | [Guide](addons/harbor.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/harbor) |
| Headlamp | `packages.headlamp` | [Guide](addons/headlamp.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/headlamp) |
| Keycloak | `packages.keycloak` | [Guide](addons/keycloak.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/keycloak) |
| Mattermost | `packages.mattermost` | [Guide](addons/mattermost.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/mattermost) |
| Mattermost Operator | `packages.mattermostOperator` | [Guide](addons/mattermost.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/mattermost-operator) |
| Metrics Server | `packages.metricsServer` | [Guide](addons/metricserver.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/metrics-server) |
| Mimir | `packages.mimir` | [Guide](addons/mimir.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/mimir) |
| MinIO | `packages.minio` | [Guide](addons/minio.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/minio) |
| MinIO Operator | `packages.minioOperator` | [Guide](addons/minio.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/minio-operator) |
| SonarQube | `packages.sonarqube` | [Guide](addons/sonarqube.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/sonarqube) |
| Thanos | `packages.thanos` | [Guide](addons/thanos.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/thanos) |
| Vault | `packages.vault` | [Guide](addons/vault.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/vault) |
| Velero | `packages.velero` | [Guide](addons/velero.md) | [Repository](https://repo1.dso.mil/big-bang/product/packages/velero) |
## Other package collections

- [Maintained packages](https://repo1.dso.mil/groups/big-bang/product/maintained) are maintained and tested independently but are not rendered directly by the umbrella chart.
- [Community packages](https://repo1.dso.mil/groups/big-bang/product/community) are owned by community maintainers and are not supported as built-in integrations.
- Use [Extra Package Deployment](../installation/environments/extra-package-deployment.md) to deploy a package that is not integrated directly.

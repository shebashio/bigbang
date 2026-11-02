# Istio hostname migration fixtures

These independently authored input/output pairs exercise issue
[#3503](https://repo1.dso.mil/big-bang/bigbang/-/work_items/3503).
Run them from the repository root:

```shell
bats --jobs 4 tests/bats/migrate-values-3-to-4/migrate-istio-hosts.bats
```

Each directory contains `input.yaml` and the complete target-4 `expected.yaml`.
The Bats suite compares sorted JSON representations, checks the input is
unchanged, and reruns the migration to check byte-for-byte idempotency. Expected
documents must be maintained independently of the script's mapping table.

| Fixture | Expected status | Purpose |
| --- | --- | --- |
| `tempo-release` | 0 | Minimal extract of the [release values example](https://repo1.dso.mil/big-bang/team/deployments/bbsil-release/-/blob/c57ded1f0cb48f4cb5708eccd31a90db227d7e1e/overlays/release/values-release.yaml); includes `expected-target-3.yaml` |
| `package-level` | 0 | Flat hosts at root, addon, and canonical package locations; injection, wildcards, and placeholders |
| `endpoint-mappings` | 0 | Every mapped endpoint, distinct endpoint lists, multiple hosts, and templates |
| `canonical-conflicts` | 0 | Canonical route hosts win, including explicit `[]` and `null` |
| `route-fields` | 0 | Already-relocated inputs, chart-value precedence over package-level hosts, literal strings, duplicates, siblings, and unrelated hosts |
| `host-templates` | 0, review diagnostic | Translate supported domain templates; preserve unsupported expressions, package-specific domain contexts, and lower-precedence hosts |
| `empty-hosts` | 0 | Absent, empty-list, and null hosts do not create routes |
| `manual-review` | 0, review diagnostic | Unknown/custom/removed endpoints and ambiguous flat lists remain in output for manual migration |

The suite also wraps representative inputs in parent HelmReleases, package
HelmRelease patches, and decrypted Secret `stringData`/`data`; tests ordered
composition, target 3, secondary sources, and malformed-input failures; and
inspects rendered package values Secrets. The existing SOPS suite covers the
encrypted-wrapper handoff with its fake SOPS executable.

To test the final VirtualService with the actual pinned Tempo package chart,
provide a checkout of Tempo chart version `3.2.1-bb.1` with its Helm
dependencies, including `bb-common` `1.6.1`, already present:

```shell
TEMPO_CHART_PATH=/path/to/tempo/chart \
  bats --filter 'actual pinned package VirtualService' \
  tests/bats/migrate-values-3-to-4/migrate-istio-hosts.bats
```

The package-chart test is skipped when `TEMPO_CHART_PATH` is unset. It renders
the umbrella values Secret, composes its common/defaults/overlays, then renders
the real package with the Istio API enabled and checks the VirtualService host.

For an individual pair:

```shell
scripts/migrate-values-3-to-4.sh --target 4 \
  tests/bats/migrate-values-3-to-4/fixtures/istio-hosts/tempo-release/input.yaml
```

## Mapping inventory and evidence

Named source endpoints below are relative to package chart `values.istio` (or
already-relocated `values.bb-common.istio`). Destinations are relative to
`values.bb-common.routes.inbound`. The historical source is the package's
`chart/values.yaml` at the listed tag, normally pinned by umbrella **3.10.0**.
Current destination names were checked against
[umbrella package templates](../../../../../chart/templates/).

| Canonical package | Historical endpoint → inbound route | Historical package chart tag |
| --- | --- | --- |
| `anchoreEnterprise` | `api` → `anchore-api`; `ui` → `anchore-ui` | `anchore-enterprise` `3.14.2-bb.4` |
| `argocd` | `argocd` → `argocd` | `9.0.3-bb.0` |
| `elasticsearchKibana` | `elasticsearch` → `elasticsearch`; `kibana` → `kibana` | `elasticsearch-kibana` `1.32.0-bb.0` |
| `fortify` | `fortify` → `fortify` | `1.1.2320154-bb.37` |
| `gitlab` | `gitlab` → `gitlab`; `registry` → `registry`; `pages` → `pages` | `9.5.1-bb.0` |
| `grafana` | `grafana` → `grafana` | `10.0.0-bb.1` |
| `harbor` | `harbor` → `harbor` | `1.18.0-bb.4` |
| `headlamp` | `headlamp` → `headlamp` | `0.36.0-bb.4` |
| `keycloak` | `keycloak` → `keycloak` | `7.1.4-bb.1` |
| `kiali` | `kiali` → `kiali` | `2.9.0-bb.2` (umbrella 2.54.0) |
| `kyvernoReporter` | `kyvernoReporter` → `policy-reporter-ui` | `kyverno-reporter` `3.5.0-bb.3` |
| `loki` | `loki` → `loki` | `6.30.1-bb.6` |
| `mattermost` | `chat` → `chat` | `11.0.2-bb.0` |
| `mimir` | Flat compatibility hosts → `mimir-gateway` | Current umbrella single-route mapping; no named legacy endpoint claimed |
| `minio` | `api` → `api`; `console` → `console` | `7.1.1-bb.12` |
| `monitoring` | `prometheus` → `monitoring-prometheus`; `alertmanager` → `monitoring-alertmanager` | `75.6.1-bb.5` |
| `neuvector` | `neuvector` → `neuvector` | `2.8.8-bb.3` |
| `sonarqube` | `sonarqube` → `sonarqube` | `2025.5.0-bb.1` |
| `tempo` | `tempoQuery` → `tempo-query` | [Commit before Tempo Query cleanup](https://repo1.dso.mil/big-bang/product/packages/tempo/-/blob/358eb4d780a85b0abe8863c44b8ab6a3add963ab/chart/values.yaml) |
| `thanos` | `thanos` → `query-frontend` | `17.2.2-bb.0` |
| `twistlock` | `console` → `console` | `0.23.0-bb.1` |
| `vault` | `vault` → `vault` | `0.31.0-bb.1` |

`packages.<name>.istio.hosts` is accepted as a compatibility migration input
for every single-route package in this inventory. The historical umbrella
package-level `istio` control exposed injection rather than a generic hostname
passthrough; chart hostname overrides normally belonged under `.values.istio`.
Accepting the reported form does not imply that it previously affected ingress.
The same flat-list conversion is accepted within chart values. Flat lists for
Anchore Enterprise, Elasticsearch/Kibana, GitLab, MinIO, and Monitoring are
ambiguous and require manual endpoint selection.

Packages without an inventoried inbound mapping are manual cases. In particular,
the removed MinIO Operator console is not mapped to a MinIO tenant route, and
an unknown GitLab endpoint is not inferred from the current `kas` route. Only
direct hosts or immediate endpoint hosts are considered; nested ServiceEntry
hosts and upstream/outbound host configuration are outside the conversion.

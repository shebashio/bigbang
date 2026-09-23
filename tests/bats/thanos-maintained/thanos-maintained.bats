#!/usr/bin/env bats

@test "maintained Thanos example renders the release and monitoring integration" {
    repo_root="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"

    run helm template bigbang "${repo_root}/chart" -f "${repo_root}/docs/migration/thanos-values-example.yaml"
    [ "${status}" -eq 0 ]

    release="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "HelmRelease" and .metadata.name == "thanos") | [.metadata.namespace, .spec.releaseName, .spec.targetNamespace, .spec.chart.spec.sourceRef.name] | join("/")' - | awk 'NF && $0 != "---"')"
    [ "${release}" = "bigbang/thanos/thanos/thanos" ]

    thanos_stores="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "Secret" and .metadata.name == "thanos-values") | .stringData."values.yaml" | from_yaml | .upstream.query.stores | length' - | awk 'NF && $0 != "---"')"
    [ "${thanos_stores}" = "2" ]

    monitoring_sidecar="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "Secret" and .metadata.name == "bigbang-monitoring-values") | .stringData.overlays | from_yaml | .upstream.prometheus | [.thanosService.enabled, .thanosServiceMonitor.enabled, .prometheusSpec.thanos.objectStorageConfig.existingSecret.name] | join("/")' - | awk 'NF && $0 != "---"')"
    [ "${monitoring_sidecar}" = "true/true/monitoring-objstore-secret" ]
}

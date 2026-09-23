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

    monitoring_ingress="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "Secret" and .metadata.name == "bigbang-monitoring-values") | .stringData.overlays | from_yaml | .networkPolicies.ingress.to."prometheus:10901".from.k8s."thanos/thanos"' - | awk 'NF && $0 != "---"')"
    [ "${monitoring_ingress}" = "true" ]

    run yq eval '[.kind, .metadata.namespace, .metadata.name, (.stringData."objstore.yml" | from_yaml | .type)] | join("/")' "${repo_root}/docs/migration/monitoring-objstore-secret-example.yaml"
    [ "${status}" -eq 0 ]
    [ "${output}" = "Secret/monitoring/monitoring-objstore-secret/s3" ]
}

@test "Grafana overlay retains other datasources and Thanos egress" {
    repo_root="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"

    run helm template bigbang "${repo_root}/chart" -f "${repo_root}/docs/migration/thanos-values-example.yaml" -f "${repo_root}/docs/migration/thanos-grafana-overlay.yaml"
    [ "${status}" -eq 0 ]

    base_datasources="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "Secret" and .metadata.name == "bigbang-grafana-values") | .stringData.defaults | from_yaml | .upstream.datasources."datasourcesbb.yaml".datasources | map(select(.uid != "prometheus")) | to_json' - | awk 'NF && $0 != "---"')"
    retained_datasources="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "Secret" and .metadata.name == "bigbang-grafana-values") | .stringData.overlays | from_yaml | .upstream.datasources."datasourcesbb.yaml".datasources | map(select(.uid != "prometheus")) | to_json' - | awk 'NF && $0 != "---"')"
    [ "${retained_datasources}" = "${base_datasources}" ]

    thanos_datasource="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "Secret" and .metadata.name == "bigbang-grafana-values") | .stringData.overlays | from_yaml | .upstream.datasources."datasourcesbb.yaml".datasources | .[] | select(.uid == "prometheus") | [.name, .url] | join("/")' - | awk 'NF && $0 != "---"')"
    [ "${thanos_datasource}" = "Thanos/http://thanos-query.thanos.svc:9090" ]

    grafana_egress="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "Secret" and .metadata.name == "bigbang-grafana-values") | .stringData.overlays | from_yaml | .networkPolicies.egress.from."*".to.k8s."thanos/thanos:9090"' - | awk 'NF && $0 != "---"')"
    [ "${grafana_egress}" = "true" ]
}

@test "strict-mTLS overlay restores Thanos certificate mounts and ServiceMonitor patch" {
    repo_root="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"

    run helm template bigbang "${repo_root}/chart" -f "${repo_root}/docs/migration/thanos-values-example.yaml" -f "${repo_root}/docs/migration/thanos-strict-mtls-overlay.yaml"
    [ "${status}" -eq 0 ]

    mount="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "Secret" and .metadata.name == "bigbang-monitoring-values") | .stringData.overlays | from_yaml | .upstream.prometheus.prometheusSpec.thanos.volumeMounts[0] | [.name, .mountPath] | join(":")' - | awk 'NF && $0 != "---"')"
    [ "${mount}" = "istio-certs:/etc/prom-certs/" ]

    patch="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "HelmRelease" and .metadata.name == "thanos") | .spec.postRenderers[0].kustomize.patches[0].patch' - | awk 'NF && $0 != "---"')"
    [[ "${patch}" == *"/spec/endpoints/0/scheme"* ]]
    [[ "${patch}" == *"/spec/endpoints/0/tlsConfig"* ]]
}

@test "SSO and Kyverno overlay preserves existing policy defaults" {
    repo_root="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"

    run helm template bigbang "${repo_root}/chart" -f "${repo_root}/docs/migration/thanos-values-example.yaml" -f "${repo_root}/docs/migration/thanos-sso-kyverno-overlay.yaml"
    [ "${status}" -eq 0 ]

    chain="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "Secret" and .metadata.name == "bigbang-authservice-values") | .stringData.defaults | from_yaml | .chains.thanos | [.match.prefix, .client_id] | join("/")' - | awk 'NF && $0 != "---"')"
    [ "${chain}" = "thanos.dev.bigbang.mil/REPLACE_ME" ]

    pod_label="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "Secret" and .metadata.name == "thanos-values") | .stringData."values.yaml" | from_yaml | .upstream.queryFrontend.podLabels.protect' - | awk 'NF && $0 != "---"')"
    [ "${pod_label}" = "keycloak" ]

    policies="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "Secret" and .metadata.name == "bigbang-kyverno-policies-values") | .stringData.overlays | from_yaml | .policies | [."disallow-auto-mount-service-account-token".exclude.any[-1].resources.namespaces[0], (."update-automountserviceaccounttokens-default".namespaces | join(","))] | join("/")' - | awk 'NF && $0 != "---"')"
    [[ "${policies}" == thanos/* ]]
    [[ "${policies}" == *monitoring* ]]
    [[ "${policies}" == *thanos ]]

    policy_pods="$(printf '%s\n' "${output}" | yq eval 'select(.kind == "Secret" and .metadata.name == "bigbang-kyverno-policies-values") | .stringData.overlays | from_yaml | .policies."update-automountserviceaccounttokens".namespaces | .[] | select(.namespace == "thanos") | .pods.allow[0]' - | awk 'NF && $0 != "---"')"
    [ "${policy_pods}" = "thanos-minio-*" ]
}

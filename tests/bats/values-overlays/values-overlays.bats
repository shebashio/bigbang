#!/usr/bin/env bats

setup() {
    export REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}" && git rev-parse --show-toplevel)"
}

@test "sidecar overlay retains Vault ingress certificates" {
    run yq eval-all \
        '(select(fileIndex == 0) * select(fileIndex == 1) * select(fileIndex == 2)) |
        ((.packages.vault.ingress.cert | length) > 0 and
        (.packages.vault.ingress.key | length) > 0)' \
        "${REPO_ROOT}/tests/test-values.yaml" \
        "${REPO_ROOT}/chart/ingress-certs.yaml" \
        "${REPO_ROOT}/tests/test-values-sidecar.yaml"

    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "sidecar overlay contains only sidecar-specific configuration" {
    run yq eval --output-format=json --indent=0 \
        '{"top": (keys | sort), "ambient": .istio.ambient.enabled}' \
        "${REPO_ROOT}/tests/test-values-sidecar.yaml"

    [ "${status}" -eq 0 ]
    [ "${output}" = '{"top":["istio"],"ambient":false}' ]
}

#!/usr/bin/env bats

setup() {
    export REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}" && git rev-parse --show-toplevel)"
}

@test "ambient overlay retains Vault ingress certificates" {
    run yq eval-all \
        '(select(fileIndex == 0) * select(fileIndex == 1) * select(fileIndex == 2)) |
        ((.addons.vault.ingress.cert | length) > 0 and
        (.addons.vault.ingress.key | length) > 0)' \
        "${REPO_ROOT}/tests/test-values.yaml" \
        "${REPO_ROOT}/chart/ingress-certs.yaml" \
        "${REPO_ROOT}/tests/test-values-ambient.yaml"

    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "ambient overlay contains only ambient-specific configuration" {
    run yq eval --output-format=json --indent=0 \
        '{"top": (keys | sort), "packages": (.packages | keys | sort), "cloudnative-pg": (.packages."cloudnative-pg" | keys | sort), "garage": (.packages.garage | keys | sort), "postgresql": (.packages.postgresql | keys | sort), "redis": (.packages.redis | keys | sort)}' \
        "${REPO_ROOT}/tests/test-values-ambient.yaml"

    [ "${status}" -eq 0 ]
    [ "${output}" = '{"top":["istio","packages"],"packages":["cloudnative-pg","garage","postgresql","redis"],"cloudnative-pg":["dependsOn"],"garage":["dependsOn","values"],"postgresql":["dependsOn","network"],"redis":["dependsOn","network"]}' ]

    run yq eval --output-format=json --indent=0 \
        '{"postgresql": ([.packages.postgresql.network.additionalPolicies[].spec.ingress[].ports[]?.port] | sort | unique), "redis": ([.packages.redis.network.additionalPolicies[].spec.ingress[].ports[]?.port] | sort | unique), "policies": ([.packages.postgresql.network.additionalPolicies[].name, .packages.redis.network.additionalPolicies[].name] | flatten | sort | unique)}' \
        "${REPO_ROOT}/tests/test-values-ambient.yaml"

    [ "${status}" -eq 0 ]
    [ "${output}" = '{"postgresql":[5432,8000,15008],"redis":[6379,15008],"policies":["allow-cloudnative-pg-status","allow-cnpg-kube-api","allow-gitlab-postgresql","allow-gitlab-redis","allow-redis-upgrade-kube-api"]}' ]
}

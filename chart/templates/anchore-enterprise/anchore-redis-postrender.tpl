{{- define "anchoreEnterprise.redisPostRenderer" }}
- kustomize:
    patches:
      - target:
          kind: Secret
          name: anchore-enterprise-ui
          namespace: anchore
        patch: |-
          - op: replace
            path: /stringData/ANCHORE_APPDB_URI
            value: 'postgresql://anchore:anchore-postgres,123@anchore-postgresql:5432/anchore'
          - op: replace
            path: /stringData/ANCHORE_REDIS_URI
            value: 'redis://:anchore-redis,123@anchore-ui-redis-master:6379'
{{- end }}

{{- define "anchoreEnterprise.smoketestPostRenderer" }}
- kustomize:
    patches:
      - target:
          kind: Secret
          name: anchore-enterprise-anchore-enterprise-5201-smoke-test
          namespace: anchore
        patch: |-
          - op: replace
            path: /containers/env/ANCHORECTL_URL
            value: 'http://anchore-enterprise-anchore-enterprise-api:8228'
{{- end }}

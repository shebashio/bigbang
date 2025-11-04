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

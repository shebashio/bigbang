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
            value: 'postgresql://{{- template "enterprise.ui.dbUser" . -}}:{{- template "enterprise.ui.dbPassword" . -}}@{{ template "enterprise.dbHostname" . }}:{{- template "enterprise.ui.dbPort" . -}}/{{- template "enterprise.ui.dbDatabase" . -}}?sslMode={{- .Values.anchoreConfig.database.sslMode -}}'
          - op: replace
            path: /stringData/ANCHORE_REDIS_URI
            value: 'redis://:{{ index .Values "ui-redis" "upstream" "auth" "password" }}@{{ template "redis.fullname" . }}-master:6379'
{{- end }}

{{- define "bigbang.gitlab.externalObjectStorageConfigured" -}}
{{- $configured := or (not (empty .Values.packages.gitlab.objectStorage.region)) (not (empty .Values.packages.gitlab.objectStorage.endpoint)) -}}
{{- $gitlabValues := .Values.packages.gitlab.values | default dict -}}
{{- $gitlabGlobalValues := dict -}}
{{- if kindIs "map" $gitlabValues -}}
  {{- $gitlabGlobalValues = (get $gitlabValues "global") | default dict -}}
{{- end -}}
{{- if kindIs "map" $gitlabGlobalValues -}}
  {{- $gitlabAppConfigValues := (get $gitlabGlobalValues "appConfig") | default dict -}}
  {{- if kindIs "map" $gitlabAppConfigValues -}}
    {{- $gitlabObjectStoreValues := (get $gitlabAppConfigValues "object_store") | default dict -}}
    {{- if kindIs "map" $gitlabObjectStoreValues -}}
      {{- $configured = or $configured (dig "enabled" false $gitlabObjectStoreValues) -}}
    {{- end -}}
    {{- range $storeName := list "lfs" "artifacts" "uploads" "packages" "externalDiffs" "terraformState" "ciSecureFiles" "agentPlanContent" "dependencyProxy" -}}
      {{- $storeValues := (get $gitlabAppConfigValues $storeName) | default dict -}}
      {{- if kindIs "map" $storeValues -}}
        {{- $connectionValues := (get $storeValues "connection") | default dict -}}
        {{- if kindIs "map" $connectionValues -}}
          {{- $configured = or $configured (not (empty $connectionValues)) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $configured -}}
{{- end }}

{{- define "bigbang.gitlab.externalRedisConfigured" -}}
{{- $configured := false -}}
{{- $gitlabValues := .Values.packages.gitlab.values | default dict -}}
{{- $gitlabGlobalValues := dict -}}
{{- if kindIs "map" $gitlabValues -}}
  {{- $gitlabGlobalValues = (get $gitlabValues "global") | default dict -}}
{{- end -}}
{{- if kindIs "map" $gitlabGlobalValues -}}
  {{- $gitlabRedisValues := (get $gitlabGlobalValues "redis") | default dict -}}
  {{- if kindIs "map" $gitlabRedisValues -}}
    {{- $configured = or
      (not (empty (get $gitlabRedisValues "host")))
      (not (empty (get $gitlabRedisValues "redisYmlOverride"))) -}}
  {{- end -}}
{{- end -}}
{{- $configured -}}
{{- end }}

{{- define "bigbang.gitlab.externalPostgresConfigured" -}}
{{- $configured := not (empty .Values.packages.gitlab.database.host) -}}
{{- $gitlabValues := .Values.packages.gitlab.values | default dict -}}
{{- $gitlabGlobalValues := dict -}}
{{- if kindIs "map" $gitlabValues -}}
  {{- $gitlabGlobalValues = (get $gitlabValues "global") | default dict -}}
{{- end -}}
{{- if kindIs "map" $gitlabGlobalValues -}}
  {{- $gitlabPsqlValues := (get $gitlabGlobalValues "psql") | default dict -}}
  {{- if kindIs "map" $gitlabPsqlValues -}}
    {{- $configured = or $configured (not (empty (get $gitlabPsqlValues "host"))) -}}
    {{- $gitlabMainPsqlValues := (get $gitlabPsqlValues "main") | default dict -}}
    {{- if kindIs "map" $gitlabMainPsqlValues -}}
      {{- $configured = or $configured (not (empty (get $gitlabMainPsqlValues "host"))) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $configured -}}
{{- end }}

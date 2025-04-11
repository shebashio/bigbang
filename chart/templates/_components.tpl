{{- define "componentGroups" -}}
application-utilities:
  - minio
  - gitlab
  - nexusRepositoryManager
core:
  - istio
  - istioGateway
  - istioOperator
  - authservice
  - externalSecrets
  - gatekeeper
observability:
  - grafana
  - monitoring
  - tempo
  - loki
  - alloy
security:
  - kyverno
  - gatekeeper
  - clusterAuditor
{{- end }}

{{- define "componentFor" -}}
  {{- $name := . -}}
  {{- $groups := include "componentGroups" . | fromYaml }}
  {{- $component := "unmatched" }}

  {{- range $group, $packages := $groups }}
    {{- range $package := $packages }}
      {{- if eq $package $name }}
        {{- $component = $group }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- $component }}
{{- end }}
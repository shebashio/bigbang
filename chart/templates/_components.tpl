{{- define "componentGroups" -}}
cluster-utilities:
  - velero
collaboration-tools:
  - mattermost
  - mattermostOperator
application-utilities:
  - minio
  - minioOperator
developer-tools:
  - gitlab
  - gitlabRunner
  - nexusRepositoryManager
core:
  - istio
  - istioCRDs
  - istioGateway
  - istioOperator
  - authservice
  - externalSecrets
  - gatekeeper
  - fluentbit
  - bbctl
  - eckOperator
  - elasticsearchKibana
  - kiali
  - promtail
  - tempo
observability:
  - grafana
  - monitoring
  - tempo
  - loki
  - alloy
  - jaeger
  - mimir
security:
  - kyverno
  - clusterAuditor
  - neuvector
  - sonarqube
  - twistlock
addons:
  - fortify
  - harbor
  - argocd
  - metricsServer
  - thanos
  - vault
  - anchore
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
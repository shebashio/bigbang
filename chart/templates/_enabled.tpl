{{- define "isEnabled" -}}
  {{- $helper := printf "%sEnabled" .name -}}
  {{- include $helper .root -}}
{{- end }}

{{- define "anchoreEnabled" -}}
  {{- .Values.addons.anchore.enabled }}
{{- end }}

{{- define "alloyEnabled" -}}
  {{- .Values.addons.alloy.enabled -}}
{{- end }}

{{- define "lokiEnabled" -}}
  {{- .Values.loki.enabled -}}
{{- end }}

{{- define "authserviceEnabled" -}}
  {{- and (include "istioEnabled" .) (or .Values.addons.authservice.enabled (and .Values.monitoring.enabled .Values.monitoring.sso.enabled) (and .Values.jaeger.enabled .Values.jaeger.sso.enabled) (and .Values.tempo.enabled .Values.tempo.sso.enabled) (and .Values.addons.thanos.enabled .Values.addons.thanos.sso.enabled)) -}}
{{- end }}

{{- define "clusterAuditorEnabled" -}}
  {{- .Values.clusterAuditor.enabled -}}
{{- end }}

{{- define "elasticsearchKibanaEnabled" -}}
  {{- .Values.elasticsearchKibana.enabled -}}
{{- end }}

{{- define "eckOperatorEnabled" -}}
  {{- or .Values.eckOperator.enabled .Values.elasticsearchKibana.enabled  -}}
{{- end }}

{{- define "externalSecretsEnabled" -}}
  {{- .Values.addons.externalSecrets.enabled -}}
{{- end }}

{{- define "fluentbitEnabled" -}}
  {{- .Values.fluentbit.enabled -}}
{{- end }}

{{- define "fortifyEnabled" -}}
  {{- .Values.addons.fortify.enabled -}}
{{- end }}

{{- define "gatekeeperEnabled" -}}
  {{- .Values.gatekeeper.enabled -}}
{{- end }}

{{- define "gitlabEnabled" -}}
  {{- .Values.addons.gitlab.enabled -}}
{{- end }}

{{- define "gitlabRunnerEnabled" -}}
  {{- .Values.addons.gitlabRunner.enabled -}}
{{- end }}

{{- define "grafanaEnabled" -}}
  {{- and (not .Values.monitoring.enabled) .Values.grafana.enabled -}}
{{- end }}

{{- define "monitoringEnabled" -}}
  {{- .Values.monitoring.enabled -}}
{{- end }}

{{- define "istioEnabled" -}}
  {{- .Values.istio.enabled -}}
{{- end }}

{{- define "istioCoreEnabled" -}}
  {{- .Values.istioCore.enabled -}}
{{- end }}

{{- define "istioGatewayEnabled" -}}
  {{- .Values.istioGateway.enabled -}}
{{- end }}

{{- define "istioOperatorEnabled" -}}
  {{- .Values.istioOperator.enabled -}}
{{- end }}

{{- define "jaegerEnabled" -}}
  {{- .Values.jaeger.enabled -}}
{{- end }}

{{- define "kialiEnabled" -}}
  {{- .Values.kiali.enabled -}}
{{- end }}

{{- define "kyvernoEnabled" -}}
  {{- or .Values.kyverno.enabled .Values.kyvernoPolicies.enabled .Values.kyvernoReporter.enabled -}}
{{- end }}

{{- define "kyvernoPoliciesEnabled" -}}
  {{- .Values.kyvernoPolicies.enabled -}}
{{- end }}

{{- define "kyvernoReporterEnabled" -}}
  {{- .Values.kyvernoReporter.enabled -}}
{{- end }}

{{- define "mattermostEnabled" -}}
  {{- .Values.addons.mattermost.enabled -}}
{{- end }}

{{- define "mattermostOperatorEnabled" -}}
  {{- .Values.addons.mattermost.enabled -}}
{{- end }}

{{- define "mimirEnabled" -}}
  {{- .Values.addons.mimir.enabled -}}
{{- end }}

{{- define "minioEnabled" -}}
  {{- .Values.addons.minio.enabled -}}
{{- end }}

{{- define "minioOperatorEnabled" -}}
  {{- .Values.addons.minioOperator.enabled -}}
{{- end }}

{{- define "neuvectorEnabled" -}}
  {{- .Values.neuvector.enabled -}}
{{- end }}

{{- define "nexusRepositoryManagerEnabled" -}}
  {{- .Values.addons.nexusRepositoryManager.enabled -}}
{{- end }}

{{- define "sonarqubeEnabled" -}}
  {{- .Values.addons.sonarqube.enabled -}}
{{- end }}

{{- define "veleroEnabled" -}}
  {{- .Values.addons.velero.enabled -}}
{{- end }}

{{- define "promtailEnabled" -}}
  {{- .Values.promtail.enabled -}}
{{- end }}

{{- define "tempoEnabled" -}}
  {{- .Values.tempo.enabled -}}
{{- end }}

{{- define "thanosEnabled" -}}
  {{- .Values.addons.thanos.enabled -}}
{{- end }}

{{- define "twistlockEnabled" -}}
  {{- .Values.twistlock.enabled -}}
{{- end }}

{{- define "vaultEnabled" -}}
  {{- .Values.addons.vault.enabled -}}
{{- end }}

{{- define "argocdEnabled" -}}
  {{- .Values.addons.argocd.enabled -}}
{{- end }}

{{- define "harborEnabled" -}}
  {{- .Values.addons.harbor.enabled -}}
{{- end }}

{{- define "keycloakEnabled" -}}
  {{- .Values.addons.keycloak.enabled -}}
{{- end }}

{{- define "bbctlEnabled" -}}
  {{- and .Values.bbctl.enabled .Values.loki.enabled .Values.promtail.enabled .Values.monitoring.enabled .Values.grafana.enabled }}
{{- end }}

{{- define "metricsServerEnabled" -}}
  {{- $enableFlag := .Values.addons.metricsServer.enabled | toString }}
  {{- $existingMetricsApi := (.Capabilities.APIVersions.Has "metrics.k8s.io/v1beta1") }}
  {{- $existingMetricsHelmRelease := (lookup "helm.toolkit.fluxcd.io/v2" "HelmRelease" "bigbang" "metrics-server") }}
  {{- or ( eq $enableFlag "true") (and (eq $enableFlag "auto") (or (not $existingMetricsApi) $existingMetricsHelmRelease)) }}
{{- end }}

{{- define "haproxyEnabled" -}}
  {{- $monitoringInjection := dig "istio" "injection" "enabled" .Values.monitoring }}
  {{- and .Values.istio.enabled .Values.monitoring.enabled .Values.monitoring.sso.enabled (eq $monitoringInjection "disabled") }}
{{- end }}

{{- define "wrapperEnabled" -}}
  {{- false -}}
{{- end }}
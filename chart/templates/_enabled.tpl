{{- define "isEnabled" -}}
  {{- $special := dict -}}
  {{- $_ := set $special "authservice" (and (include "istioEnabled" .root) (or .root.Values.addons.authservice.enabled (and .root.Values.monitoring.enabled .root.Values.monitoring.sso.enabled) (and .root.Values.jaeger.enabled .root.Values.jaeger.sso.enabled) (and .root.Values.tempo.enabled .root.Values.tempo.sso.enabled) (and .root.Values.addons.thanos.enabled .root.Values.addons.thanos.sso.enabled))) -}}
  {{- $_ := set $special "eckOperator" (or .root.Values.eckOperator.enabled .root.Values.elasticsearchKibana.enabled) -}}
  {{- $_ := set $special "grafana" (and (not .root.Values.monitoring.enabled) .root.Values.grafana.enabled) -}}
  {{- $_ := set $special "kyverno" (or .root.Values.kyverno.enabled .root.Values.kyvernoPolicies.enabled .root.Values.kyvernoReporter.enabled) -}}
  {{- $_ := set $special "bbctl" (and .root.Values.bbctl.enabled .root.Values.loki.enabled .root.Values.promtail.enabled .root.Values.monitoring.enabled .root.Values.grafana.enabled) -}}
  {{- $_ := set $special "metricsServer" (or (eq (.root.Values.addons.metricsServer.enabled | toString) "true") (and (eq (.root.Values.addons.metricsServer.enabled | toString) "auto") (or (not (.root.Capabilities.APIVersions.Has "metrics.k8s.io/v1beta1")) (lookup "helm.toolkit.fluxcd.io/v2" "HelmRelease" "bigbang" "metrics-server")))) -}}
  {{- $_ := set $special "haproxy" (and .root.Values.istio.enabled .root.Values.monitoring.enabled .root.Values.monitoring.sso.enabled (eq (dig "istio" "injection" "enabled" .root.Values.monitoring) "disabled")) -}}
  {{- $_ := set $special "istioGateway" (and .root.Values.istioCore.enabled .root.Values.istioGateway.enabled) -}}
  {{- $_ := set $special "wrapper" false -}}

  {{- if hasKey $special .name -}}
    {{- get $special .name -}}
  {{- else -}}
    {{- $allPackages := include "bigbang.allPackages" .root | fromYaml -}}
    {{- $pkg := index $allPackages (last (splitList "." .name)) -}}
    {{- if $pkg -}}
      {{- $pkg.enabled -}}
    {{- else -}}
      {{- false -}}
    {{- end -}}
  {{- end -}}
{{- end }}
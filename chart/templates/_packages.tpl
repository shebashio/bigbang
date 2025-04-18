{{/*
Helper: bigbang.packages.all
Output all packages (top-level + addons) regardless of enabled
*/}}
{{- define "bigbang.packages.all" -}}
  {{- $all := dict -}}

  {{- /* Top-level packages (those with a sourceType) */ -}}
  {{- range $name, $pkg := .Values -}}
    {{- if and (kindIs "map" $pkg) (hasKey $pkg "sourceType") -}}
      {{- $_ := set $all $name $pkg -}}
    {{- end -}}
  {{- end -}}

  {{- /* Addons */ -}}
  {{- range $name, $addon := .Values.addons -}}
    {{- $_ := set $all $name $addon -}}
  {{- end -}}

  {{- $all | toYaml -}}
{{- end -}}

{{/*
Helper: bigbang.packages.enabled
Output only enabled packages
*/}}
{{- define "bigbang.packages.enabled" -}}
  {{- $enabled := dict -}}
  {{- $all := include "bigbang.packages.all" . | fromYaml -}}
  {{- range $name, $pkg := $all }}
    {{- if and (hasKey $pkg "enabled") ($pkg.enabled) }}
      {{- $_ := set $enabled $name $pkg -}}
    {{- end -}}
  {{- end -}}

  {{- $enabled | toYaml -}}
{{- end -}}

{{/*
Helper: getNamespace
Get namespace for a package, with special cases for certain packages
*/}}
{{- define "bigbang.package.getNamespace" -}}
{{- $name := . -}}
{{- if eq $name "loki" -}}
logging
{{- else if eq $name "elasticsearchKibana" -}}
logging
{{- else if eq $name "gatekeeper" -}}
gatekeeper-system
{{- else if eq $name "grafana" -}}
monitoring
{{- else if eq $name "istio" -}}
istio-system
{{- else if eq $name "istiod" -}}
istio-system
{{- else if eq $name "istioOperator" -}}
istio-operator
{{- else if eq $name "istioCRDs" -}}
istio-system
{{- else if eq $name "kyvernoPolicies" -}}
kyverno
{{- else -}}
{{- $name -}}
{{- end -}}
{{- end -}}

{{/*
Helper: getName
Get name for a package, mostly kebabcase special cases for certain packages
*/}}
{{- define "bigbang.package.getName" -}}
{{- $name := . -}}
{{- if eq $name "istioCRDs" -}}
istio-crds
{{- else -}}
{{- $name | kebabcase -}}
{{- end -}}
{{- end -}}

{{- define "bigbang.package.enabled" -}}
  {{- $special := dict -}}
  {{- $_ := set $special "authservice" (and (include "istioEnabled" .root) (or .root.Values.addons.authservice.enabled (and .root.Values.monitoring.enabled .root.Values.monitoring.sso.enabled) (and .root.Values.jaeger.enabled .root.Values.jaeger.sso.enabled) (and .root.Values.tempo.enabled .root.Values.tempo.sso.enabled) (and .root.Values.addons.thanos.enabled .root.Values.addons.thanos.sso.enabled))) -}}
  {{- $_ := set $special "eckOperator" (or .root.Values.eckOperator.enabled .root.Values.elasticsearchKibana.enabled) -}}
  {{- $_ := set $special "grafana" (and (not .root.Values.monitoring.enabled) .root.Values.grafana.enabled) -}}
  {{- $_ := set $special "kyverno" (or .root.Values.kyverno.enabled .root.Values.kyvernoPolicies.enabled .root.Values.kyvernoReporter.enabled) -}}
  {{- $_ := set $special "bbctl" (and .root.Values.bbctl.enabled .root.Values.loki.enabled .root.Values.promtail.enabled .root.Values.monitoring.enabled .root.Values.grafana.enabled) -}}
  {{- $_ := set $special "metricsServer" (or (eq (.root.Values.addons.metricsServer.enabled | toString) "true") (and (eq (.root.Values.addons.metricsServer.enabled | toString) "auto") (or (not (.root.Capabilities.APIVersions.Has "metrics.k8s.io/v1beta1")) (lookup "helm.toolkit.fluxcd.io/v2" "HelmRelease" "bigbang" "metrics-server")))) -}}
  {{- $_ := set $special "haproxy" (and .root.Values.istio.enabled .root.Values.monitoring.enabled .root.Values.monitoring.sso.enabled (eq (dig "istio" "injection" "enabled" .root.Values.monitoring) "disabled")) -}}
  {{- $_ := set $special "istioGateway" (and .root.Values.istiod.enabled .root.Values.istioGateway.enabled) -}}
  {{- $_ := set $special "wrapper" false -}}

  {{- if hasKey $special .name -}}
    {{- get $special .name -}}
  {{- else -}}
    {{- $allPackages := include "bigbang.packages.all" .root | fromYaml -}}
    {{- $pkg := index $allPackages (last (splitList "." .name)) -}}
    {{- if $pkg -}}
      {{- $pkg.enabled -}}
    {{- else -}}
      {{- false -}}
    {{- end -}}
  {{- end -}}
{{- end }}
{{/*
Helper: bigbang.allPackages
Output all packages (top-level + addons) regardless of enabled
*/}}
{{- define "bigbang.allPackages" -}}
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
Helper: bigbang.enabledPackages
Output only enabled packages
*/}}
{{- define "bigbang.enabledPackages" -}}
  {{- $enabled := dict -}}
  {{- $all := include "bigbang.allPackages" . | fromYaml -}}
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
{{- else if eq $name "istioCore" -}}
istio-system
{{- else if eq $name "istioOperator" -}}
istio-operator
{{- else if eq $name "kyvernoPolicies" -}}
kyverno
{{- else -}}
{{- $name -}}
{{- end -}}
{{- end -}}

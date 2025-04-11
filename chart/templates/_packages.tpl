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
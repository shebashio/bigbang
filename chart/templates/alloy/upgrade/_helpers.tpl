{{- define "alloy.shouldDeployUpgradeResources" -}}
{{/* Define upgradeVersion inside the template so it's available when the template is used */}}
{{- $upgradeVersion := "3.48.0" -}} #Set to major upgrade to test
{{- if and .Values.addons.alloy.autoRollingUpgrade.enabled .Values.addons.alloy.enabled -}}
  {{- $helmRelease := lookup "helm.toolkit.fluxcd.io/v2" "HelmRelease" "bigbang" "alloy" -}}
  {{- if $helmRelease -}}
    {{- $currentVersion := dig "metadata" "labels" "helm.sh/chart" "<missing>" $helmRelease | trimPrefix (print .Chart.Name "-") -}}
    {{- if semverCompare (print "<" $upgradeVersion) $currentVersion -}}
      true
    {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
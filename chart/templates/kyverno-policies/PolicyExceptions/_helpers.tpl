{{/*
Normalize raw policy exception snippets into the kyverno-policies chart's
additionalPolicyExceptions values schema.
*/}}
{{- define "bigbang.policyexceptions.normalize" -}}
{{- $raw := .raw | default "" -}}
{{- if $raw -}}
{{- $exceptions := fromYaml $raw -}}
{{- range $name, $exception := $exceptions }}
{{- if $exception }}
{{ $name }}:
  enabled: {{ default true $exception.enabled }}
  kind: {{ default "PolicyException" $exception.kind }}
  namespace: {{ default (dig "metadata" "namespace" "kyverno" $exception) $exception.namespace }}
  annotations:
{{- $annotations := default (dig "metadata" "annotations" dict $exception) $exception.annotations }}
{{- if $annotations }}
{{ toYaml $annotations | nindent 4 }}
{{- else }}
    {}
{{- end }}
  metadata:
    namespace: {{ default (dig "metadata" "namespace" "kyverno" $exception) $exception.namespace }}
    annotations:
{{- if $annotations }}
{{ toYaml $annotations | nindent 6 }}
{{- else }}
      {}
{{- end }}
{{- $labels := default (dig "metadata" "labels" dict $exception) $exception.labels }}
{{- if $labels }}
    labels:
{{ toYaml $labels | nindent 6 }}
{{- end }}
  spec:
{{ toYaml $exception.spec | nindent 4 }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

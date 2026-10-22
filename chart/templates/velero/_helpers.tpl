{{/* Match the upstream flag that actually creates the Velero node-agent DaemonSet. */}}
{{- define "bigbang.velero.nodeAgentEnabled" -}}
{{- $velero := default (dict) (get (default (dict) .Values.packages) "velero") -}}
{{- and (default false (get $velero "enabled")) (dig "upstream" "deployNodeAgent" false (default (dict) (get $velero "values"))) -}}
{{- end -}}

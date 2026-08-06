{{- define "postgresql.fullname" -}}
{{- default .Release.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "postgresql.labels" -}}
app.kubernetes.io/name: {{ include "postgresql.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "postgresql.credentialsSecret" -}}
{{- default .Values.database.credentials.secretName .Values.database.credentials.existingSecret -}}
{{- end -}}

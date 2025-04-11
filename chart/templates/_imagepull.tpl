{{/*
Generate an Image Pull Secret resource
*/}}
{{- define "genImagePullSecret" -}}
{{- if ( include "imagePullSecret" .root ) }}
apiVersion: v1
kind: Secret
metadata:
  name: private-registry
  namespace: {{ (include "bigbang.package.getNamespace" .name) | kebabcase }}
  labels:
    app.kubernetes.io/name: {{ .name | kebabcase }}
    app.kubernetes.io/component: {{ include "componentFor" .name }}
    {{- include "commonLabels" .root | nindent 4}} 
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: {{ template "imagePullSecret" .root }}
{{- end }}
{{- end }}

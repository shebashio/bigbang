{{- define "KyvernoReporter.ServiceMonitorPostRenderers" }}
    - kustomize:
        patches:
          - target:
              kind: ServiceMonitor
              name: {{ include "monitoring.fullname" . }}
            patch: |-
              - op: add
                path: /spec/endpoints/0/scheme
                value: https
              {{- if .Values.monitoring.kyverno.serviceMonitor.tlsConfig }}
              - op: add
                path: /spec/endpoints/0/tlsConfig
                value: {{ toYaml .Values.monitoring.kyverno.serviceMonitor.tlsConfig | nindent 18 }}
              {{- end }}
{{- end }}
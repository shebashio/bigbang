{{- define "KyvernoReporter.ServiceMonitorPostRenderer" }}
    - kustomize:
        patches:
          - target:
              kind: ServiceMonitor
              name: policy-reporter-monitoring
              namespace: kyverno-reporter
            patch: |-
              - op: add
                path: /spec/endpoints/0/scheme
                value: https
              - op: add
                path: /spec/endpoints/0/tlsConfig
                value: {{ toYaml .Values.monitoring.kyverno.serviceMonitor.tlsConfig | nindent 18 }}
{{- end }}
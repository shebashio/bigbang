{{- define "fluentbit.podPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /spec/template/spec/containers/0/name
            value: fluent-bit
        target:
          kind: DaemonSet
          name: fluentbit-fluent-bit
          namespace: fluentbit
      {{- if eq (include "metricScrapingEnabled" .) "true" }}
      - patch: |
          - op: add
            path: /spec/ports/-
            value:
              name: tcp-http
              port: 2021
              targetPort: http
              protocol: TCP
        target:
          kind: Service
          name: fluentbit-fluent-bit
          namespace: fluentbit
      - patch: |
          - op: replace
            path: /spec/endpoints/0/port
            value: tcp-http
          - op: add
            path: /spec/endpoints/0/enableHttp2
            value: false
        target:
          kind: ServiceMonitor
          name: fluentbit-fluent-bit
          namespace: monitoring
      {{- end }}
{{- end }}

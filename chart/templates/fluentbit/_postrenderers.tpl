{{- define "fluentbit.podPostRenderers" }}
- kustomize:
    patches:
      {{- if eq (include "metricScrapingEnabled" .) "true" }}
      - patch: |
          - op: replace
            path: /metadata/namespace
            value: monitoring
        target:
          kind: ServiceMonitor
          name: fluentbit-fluent-bit
          namespace: fluentbit
      - patch: |
          - op: replace
            path: /metadata/namespace
            value: monitoring
        target:
          kind: ConfigMap
          name: fluentbit-fluent-bit-dashboard
          namespace: fluentbit
      {{- end }}
{{- end }}

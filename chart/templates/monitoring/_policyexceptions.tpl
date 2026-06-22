{{- /*
Kyverno PolicyExceptions for Monitoring (kube-prometheus-stack) workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.monitoring" -}}
{{- if .Values.monitoring.enabled }}
# Prometheus node-exporter mounts host /, /proc and /sys to gather node metrics.
monitoring-node-exporter:
  spec:
    policyRefs:
      - name: restrict-host-path-mount
        kind: ValidatingPolicy
      - name: restrict-volume-types
        kind: ValidatingPolicy
    matchConditions:
      - name: monitoring-node-exporter
        expression: >-
          (object.metadata.namespace == 'monitoring' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('monitoring-monitoring-prometheus-node-exporter'))
# The Flux controllers (managed by the monitoring stack's flux-system namespace)
# legitimately mount their API token.
monitoring-flux-system:
  spec:
    policyRefs:
      - name: disallow-auto-mount-service-account-token
        kind: ValidatingPolicy
    matchConditions:
      - name: flux-controllers
        expression: >-
          (object.metadata.namespace == 'flux-system' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('notification-controller') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('helm-controller') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('source-controller') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('kustomize-controller')
          ))
{{- end }}
{{- end -}}

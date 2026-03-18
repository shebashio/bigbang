{{- define "bigbang.policyexceptions.monitoring.cel" }}
monitoring-disallow-auto-mount-service-account-token-exception:
  metadata:
    namespace: kyverno
    labels:
      app: monitoring
  spec:
    policyRefs:
    - name: disallow-auto-mount-service-account-token
      kind: ValidatingPolicy
    matchConditions:
    - name: match-flux-controllers
      expression: "object.metadata.namespace == 'flux-system' && object.kind in ['Pod', 'Deployment', 'StatefulSet'] && (object.metadata.name.startsWith('notification-controller') || object.metadata.name.startsWith('helm-controller') || object.metadata.name.startsWith('source-controller') || object.metadata.name.startsWith('kustomize-controller'))"
monitoring-disallow-tolerations-exception:
  metadata:
    namespace: kyverno
    labels:
      app: monitoring
  spec:
    policyRefs:
    - name: disallow-tolerations
      kind: ValidatingPolicy
    matchConditions:
    - name: match-node-exporter
      expression: "object.metadata.namespace == 'monitoring' && object.metadata.name.startsWith('monitoring-monitoring-prometheus-node-exporter')"
monitoring-restrict-host-path-mount-exception:
  metadata:
    namespace: kyverno
    labels:
      app: monitoring
  spec:
    policyRefs:
    - name: restrict-host-path-mount
      kind: ValidatingPolicy
    matchConditions:
    - name: match-node-exporter
      expression: "object.metadata.namespace == 'monitoring' && object.metadata.name.startsWith('monitoring-monitoring-prometheus-node-exporter')"
monitoring-restrict-volume-types-exception:
  metadata:
    namespace: kyverno
    labels:
      app: monitoring
  spec:
    policyRefs:
    - name: restrict-volume-types
      kind: ValidatingPolicy
    matchConditions:
    - name: match-node-exporter
      expression: "object.metadata.namespace == 'monitoring' && object.metadata.name.startsWith('monitoring-monitoring-prometheus-node-exporter')"
{{- end }}
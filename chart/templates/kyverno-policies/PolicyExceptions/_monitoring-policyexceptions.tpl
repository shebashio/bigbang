{{- define "bigbang.policyexceptions.monitoring" }}
monitoring-disallow-auto-mount-service-account-token-exception:
  metadata:
		namespace: kyverno
    labels:
      app: monitoring
  spec:
    exceptions:
    - policyName: disallow-auto-mount-service-account-token
      ruleNames:
      - disallow-auto-mount-service-account-token
    match:
      any:
      - resources:
          kinds:
          - Pod
          - Deployment
          - StatefulSet
          names:
          - notification-controller*
          - helm-controller*
          - source-controller*
          - kustomize-controller*
          namespaces:
          - flux-system
monitoring-disallow-tolerations-exception:
  metadata:
		namespace: kyverno
    labels:
      app: monitoring
  spec:
    exceptions:
    - policyName: disallow-tolerations
      ruleNames:
      - disallow-tolerations
    match:
      any:
      - resources:
          names:
          - monitoring-monitoring-prometheus-node-exporter*
          namespaces:
          - monitoring
monitoring-restrict-host-path-mount-exception:
  metadata:
		namespace: kyverno
    labels:
      app: monitoring
  spec:
    exceptions:
    - policyName: restrict-host-path-mount
      ruleNames:
      - restrict-host-path-mount
    match:
      any:
      - resources:
          names:
          - monitoring-monitoring-prometheus-node-exporter*
          namespaces:
          - monitoring
monitoring-restrict-volume-types-exception:
  metadata:
		namespace: kyverno
    labels:
      app: monitoring
  spec:
    exceptions:
    - policyName: restrict-volume-types
      ruleNames:
      - restrict-volume-types
    match:
      any:
      - resources:
          names:
          - monitoring-monitoring-prometheus-node-exporter*
          namespaces:
          - monitoring
{{- end }}
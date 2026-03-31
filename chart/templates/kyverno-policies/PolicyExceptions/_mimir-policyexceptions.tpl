{{- define "bigbang.policyexceptions.mimir" }}
mimir-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: mimir
  annotations:
    policies.kyverno.io/description: "For mimir smoke test jobs that require root"
  spec:
    exceptions:
    - policyName: add-default-capability-drop
      ruleNames:
      - add-default-capability-drop
    match:
      any:
      - resources:
          names:
          - mimir-mimir-smoke-test*
          namespaces:
          - mimir
mimir-require-drop-all-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: mimir
    annotations:
      policies.kyverno.io/description: "For mimir smoke test jobs that require root"
  spec:
    exceptions:
    - policyName: require-drop-all-capabilities
      ruleNames:
      - require-drop-all-capabilities
    match:
      any:
      - resources:
          names:
          - mimir-mimir-smoke-test-*
          namespaces:
          - mimir
{{- end }}
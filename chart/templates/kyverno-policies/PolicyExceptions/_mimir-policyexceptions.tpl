{{- define "bigbang.policyexceptions.mimir" }}
mimir-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: mimir
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
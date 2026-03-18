{{- define "bigbang.policyexceptions.mimir.cel" }}
mimir-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: mimir
  spec:
    policyRefs:
    - name: add-default-capability-drop
      kind: MutatingPolicy
    matchConditions:
    - name: match-mimir-smoke-test
      expression: "object.metadata.namespace == 'mimir' && object.metadata.name.startsWith('mimir-mimir-smoke-test')"
mimir-require-drop-all-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: mimir
  spec:
    policyRefs:
    - name: require-drop-all-capabilities
      kind: ValidatingPolicy
    matchConditions:
    - name: match-mimir-smoke-test
      expression: "object.metadata.namespace == 'mimir' && object.metadata.name.startsWith('mimir-mimir-smoke-test-')"
{{- end }}
{{- define "bigbang.policyexceptions.velero.cel" }}
velero-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: velero
  spec:
    policyRefs:
    - name: add-default-capability-drop
      kind: MutatingPolicy
    matchConditions:
    - name: match-velero-backup-restore-test
      expression: "object.metadata.namespace == 'velero' && object.metadata.name.startsWith('velero-backup-restore-test')"
velero-require-drop-all-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: velero
  spec:
    policyRefs:
    - name: require-drop-all-capabilities
      kind: ValidatingPolicy
    matchConditions:
    - name: match-velero-backup-restore-test
      expression: "object.metadata.namespace == 'velero' && object.metadata.name.startsWith('velero-backup-restore-test')"
{{- end }}
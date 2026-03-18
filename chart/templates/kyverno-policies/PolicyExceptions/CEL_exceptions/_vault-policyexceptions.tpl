{{- define "bigbang.policyexceptions.vault.cel" }}
vault-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: vault
  spec:
    policyRefs:
    - name: add-default-capability-drop
      kind: MutatingPolicy
    matchConditions:
    - name: match-vault-job-init
      expression: "object.metadata.namespace == 'vault' && object.metadata.name.startsWith('vault-vault-job-init')"
{{- end }}
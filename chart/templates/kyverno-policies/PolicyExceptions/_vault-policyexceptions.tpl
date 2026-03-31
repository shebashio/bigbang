{{- define "bigbang.policyexceptions.vault" }}
vault-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: vault
    annotations:
      policies.kyverno.io/description: "For vault jobs that require root access"
  spec:
    exceptions:
    - policyName: add-default-capability-drop
      ruleNames:
      - add-default-capability-drop
    match:
      any:
      - resources:
          names:
          - vault-vault-job-init*
          namespaces:
          - vault
{{- end }}
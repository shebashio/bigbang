{{- define "bigbang.policyexceptions.vault" }}
vault-add-default-capability-drop-exception:
  metadata:
    labels:
      app: vault
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
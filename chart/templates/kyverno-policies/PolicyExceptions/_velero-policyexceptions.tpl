{{- define "bigbang.policyexceptions.velero" }}
velero-add-default-capability-drop-exception: kyverno.io/v2
  metadata:
    labels:
      app: velero
  spec:
    exceptions:
    - policyName: add-default-capability-drop
      ruleNames:
      - add-default-capability-drop
    match:
      any:
      - resources:
          names:
          - velero-backup-restore-test*
          namespaces:
          - velero
velero-require-drop-all-capabilities-exception:
  metadata:
    labels:
      app: velero
  spec:
    exceptions:
    - policyName: require-drop-all-capabilities
      ruleNames:
      - require-drop-all-capabilities
    match:
      any:
      - resources:
          names:
          - velero-backup-restore-test*
          namespaces:
          - velero
{{- end }}
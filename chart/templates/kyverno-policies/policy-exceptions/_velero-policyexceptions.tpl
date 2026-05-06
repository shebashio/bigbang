{{- define "bigbang.policyexceptions.velero" }}
velero-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: velero
    annotations:
      policies.kyverno.io/description: "# Velero.  The node agent backup tool requires root group access to see the host's runtime pod directory which is
      # mounted inside velero/node agent pods."
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
    namespace: kyverno
    labels:
      app: velero
    annotations:
      policies.kyverno.io/title: Velero require-drop-all-capabilities exception
      policies.kyverno.io/category: Velero
      policies.kyverno.io/subject: Pod, Job
      policies.kyverno.io/description: "# Velero.  The node agent backup tool requires root group access to see the host's runtime pod directory which is
      # mounted inside velero/node agent pods."
  spec:
    exceptions:
    - policyName: require-drop-all-capabilities
      ruleNames:
      - drop-all-capabilities
    match:
      any:
      - resources:
          names:
          - velero-backup-restore-test*
          namespaces:
          - velero
velero-restrict-user-id-exception:
  metadata:
    namespace: kyverno
    labels:
      app: velero
    annotations:
      policies.kyverno.io/title: Velero restrict-user-id exception
      policies.kyverno.io/category: Best Practices (Security)
      policies.kyverno.io/subject: Pod, Job
      policies.kyverno.io/description: "# Velero.  The node agent backup tool requires root group access to see the host's runtime pod directory which is
      # mounted inside velero/node agent pods."
  spec:
    exceptions:
    - policyName: restrict-user-id
      ruleNames:
      - validate-pod-userid
      - validate-containers-userid
    match:
      any:
      - resources:
          namespaces:
          - velero
          names:
          - node-agent*
{{- end }}

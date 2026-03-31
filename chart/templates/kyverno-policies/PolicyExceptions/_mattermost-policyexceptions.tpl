{{- define "bigbang.policyexceptions.mattermost" }}
mattermost-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: mattermost
    annotations:
      policies.kyverno.io/title: Mattermost add-default-securitycontext exception
      policies.kyverno.io/category: Mattermost
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Mattermost fails when policy was implemented"
  spec:
    exceptions:
    - policyName: add-default-securitycontext
      ruleNames:
      - add-default-securitycontext
    match:
      any:
      - resources:
          names:
          - mattermost-*
          namespaces:
          - mattermost
          - mattermost-operator
{{- end }}
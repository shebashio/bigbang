{{- define "bigbang.policyexceptions.mattermost" }}
mattermost-add-default-securitycontext-exception:
  metadata:
		namespace: kyverno
    labels:
      app: mattermost
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
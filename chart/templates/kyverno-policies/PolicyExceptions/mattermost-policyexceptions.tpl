{{- define "bigbang.policyexceptions.mattermost" }}
  apiVersion: kyverno.io/v2
  kind: PolicyException
  metadata:
    annotations:
    labels:
      app: mattermost
    name: mattermost-add-default-securitycontext-exception
    namespace: {{ .Release.Namespace }}
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
{{- define "bigbang.policyexceptions.mattermost.cel" }}
mattermost-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: mattermost
  spec:
    policyRefs:
    - name: add-default-securitycontext
      kind: MutatingPolicy
    matchConditions:
    - name: match-mattermost
      expression: "object.metadata.namespace in ['mattermost', 'mattermost-operator'] && object.metadata.name.startsWith('mattermost-')"
{{- end }}
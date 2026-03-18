{{- define "bigbang.policyexceptions.headlamp.cel" }}
headlamp-disallow-auto-mount-service-account-token-exception:
  metadata:
    namespace: kyverno
    labels:
      app: headlamp
  spec:
    policyRefs:
    - name: disallow-auto-mount-service-account-token
      kind: ValidatingPolicy
    matchConditions:
    - name: match-headlamp
      expression: "object.metadata.namespace == 'headlamp' && object.metadata.name.startsWith('headlamp')"
{{- end }}
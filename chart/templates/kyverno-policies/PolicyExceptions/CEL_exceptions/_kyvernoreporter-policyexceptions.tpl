{{- define "bigbang.policyexceptions.kyvernoreporter.cel" }}
kyvernoreporter-disallow-auto-mount-service-account-token-exception:
  metadata:
    namespace: kyverno
    labels:
      app: kyvernoreporter
  spec:
    policyRefs:
    - name: disallow-auto-mount-service-account-token
      kind: ValidatingPolicy
    matchConditions:
    - name: match-kyverno-reporter
      expression: "object.metadata.namespace == 'kyverno-reporter' && object.kind in ['Pod', 'Deployment'] && object.metadata.name.startsWith('kyverno-reporter')"
{{- end }}
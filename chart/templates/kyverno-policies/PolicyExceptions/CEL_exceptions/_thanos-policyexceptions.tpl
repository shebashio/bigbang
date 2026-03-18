{{- define "bigbang.policyexceptions.thanos.cel" }}
thanos-disallow-auto-mount-service-account-token-exception:
  metadata:
    namespace: kyverno
    labels:
      app: thanos
  spec:
    policyRefs:
    - name: disallow-auto-mount-service-account-token
      kind: ValidatingPolicy
    matchConditions:
    - name: match-thanos-compactor
      expression: "object.metadata.namespace == 'thanos' && object.kind in ['Pod', 'Deployment', 'StatefulSet'] && object.metadata.name.startsWith('thanos-compactor')"
{{- end }}
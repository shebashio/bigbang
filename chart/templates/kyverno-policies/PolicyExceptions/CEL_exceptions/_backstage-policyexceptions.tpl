{{- define "bigbang.policyexceptions.backstage.cel" }}
backstage-disallow-auto-mount-service-account-token-exception:
  metadata:
    namespace: kyverno
    labels:
      app: backstage
  spec:
    policyRefs:
    - name: disallow-auto-mount-service-account-token
      kind: ValidatingPolicy
    matchConditions:
    - name: match-backstage-resources
      expression: "object.metadata.namespace == 'backstage' && object.kind in ['Pod', 'Deployment', 'ReplicaSet', 'ServiceAccount'] && object.metadata.name.startsWith('backstage')"
{{- end }}
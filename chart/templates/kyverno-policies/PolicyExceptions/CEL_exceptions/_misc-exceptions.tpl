
{{- define "bigbang.policyexceptions.misc.cel" }}
kube-system-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: kube
  spec:
    policyRefs:
    - name: add-default-securitycontext
      kind: MutatingPolicy
    matchConditions:
    - name: match-kube-system
      expression: "object.metadata.namespace == 'kube-system'"
kube-system-require-non-root-group-exception:
  metadata:
    namespace: kyverno
    labels:
      app: kube
  spec:
    policyRefs:
    - name: require-non-root-group
      kind: ValidatingPolicy
    matchConditions:
    - name: match-kube-system
      expression: "object.metadata.namespace == 'kube-system'"
kube-system-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: kube
  spec:
    policyRefs:
    - name: require-non-root-user
      kind: ValidatingPolicy
    matchConditions:
    - name: match-kube-system
      expression: "object.metadata.namespace == 'kube-system'"
{{- end }}
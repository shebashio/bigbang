{{- define "bigbang.policyexceptions.alloy.cel" }}
alloy-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
  spec:
    policyRefs:
    - name: add-default-securitycontext
      kind: MutatingPolicy
    matchConditions:
    - name: match-alloy-logs
      expression: "object.metadata.namespace == 'alloy' && object.metadata.name.startsWith('alloy-alloy-logs')"
alloy-require-non-root-group-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
  spec:
    policyRefs:
    - name: require-non-root-group
      kind: ValidatingPolicy
    matchConditions:
    - name: match-alloy-logs
      expression: "object.metadata.namespace == 'alloy' && object.metadata.name.startsWith('alloy-alloy-logs')"
alloy-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
  spec:
    policyRefs:
    - name: require-non-root-user
      kind: ValidatingPolicy
    matchConditions:
    - name: match-alloy-logs
      expression: "object.metadata.namespace == 'alloy' && object.metadata.name.startsWith('alloy-alloy-logs')"
alloy-restrict-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
  spec:
    policyRefs:
    - name: restrict-capabilities
      kind: ValidatingPolicy
    matchConditions:
    - name: match-alloy-resources
      expression: "object.metadata.namespace == 'alloy' && (object.metadata.name.startsWith('alloy-alloy-metrics') || object.metadata.name.startsWith('alloy-alloy-receiver') || object.metadata.name.startsWith('alloy-alloy-logs') || object.metadata.name.startsWith('alloy-alloy-singleton'))"
alloy-restrict-host-path-mount-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
  spec:
    policyRefs:
    - name: restrict-host-path-mount
      kind: ValidatingPolicy
    matchConditions:
    - name: match-alloy-logs
      expression: "object.metadata.namespace == 'alloy' && object.metadata.name.startsWith('alloy-alloy-logs')"
alloy-restrict-selinux-type-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
  spec:
    policyRefs:
    - name: restrict-selinux-type
      kind: ValidatingPolicy
    matchConditions:
    - name: match-alloy-logs
      expression: "object.metadata.namespace == 'alloy' && object.metadata.name.startsWith('alloy-alloy-logs-')"
alloy-restrict-volume-types-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
  spec:
    policyRefs:
    - name: restrict-volume-types
      kind: ValidatingPolicy
    matchConditions:
    - name: match-alloy-logs
      expression: "object.metadata.namespace == 'alloy' && object.metadata.name.startsWith('alloy-alloy-logs')"
{{- end }}
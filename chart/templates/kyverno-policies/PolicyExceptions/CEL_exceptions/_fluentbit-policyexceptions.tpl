{{- define "bigbang.policyexceptions.fluentbit.cel" }}
fluentbit-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: fluentbit
  spec:
    policyRefs:
    - name: add-default-securitycontext
      kind: MutatingPolicy
    matchConditions:
    - name: match-fluentbit
      expression: "object.metadata.namespace == 'fluentbit' && object.metadata.name.startsWith('fluentbit-fluent-bit')"
fluentbit-disallow-privileged-containers-exception:
  metadata:
    namespace: kyverno
    labels:
      app: fluentbit
  spec:
    policyRefs:
    - name: disallow-privileged-containers
      kind: ValidatingPolicy
    matchConditions:
    - name: match-fluentbit
      expression: "object.metadata.namespace == 'fluentbit' && object.metadata.name.startsWith('fluentbit-fluent-bit')"
fluentbit-disallow-tolerations-exception:
  metadata:
    namespace: kyverno
    labels:
      app: fluentbit
  spec:
    policyRefs:
    - name: disallow-tolerations
      kind: ValidatingPolicy
    matchConditions:
    - name: match-fluentbit
      expression: "object.metadata.namespace == 'fluentbit' && object.metadata.name.startsWith('fluentbit-fluent-bit')"
fluentbit-require-non-root-group-exception:
  metadata:
    namespace: kyverno
    labels:
      app: fluentbit
  spec:
    policyRefs:
    - name: require-non-root-group
      kind: ValidatingPolicy
    matchConditions:
    - name: match-fluentbit
      expression: "object.metadata.namespace == 'fluentbit' && object.metadata.name.startsWith('fluentbit-fluent-bit')"
fluentbit-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: fluentbit
  spec:
    policyRefs:
    - name: require-non-root-user
      kind: ValidatingPolicy
    matchConditions:
    - name: match-fluentbit
      expression: "object.metadata.namespace == 'fluentbit' && object.metadata.name.startsWith('fluentbit-fluent-bit')"
fluentbit-restrict-host-path-mount-exception:
  metadata:
    namespace: kyverno
    labels:
      app: fluentbit
  spec:
    policyRefs:
    - name: restrict-host-path-mount
      kind: ValidatingPolicy
    matchConditions:
    - name: match-fluentbit
      expression: "object.metadata.namespace == 'fluentbit' && object.metadata.name.startsWith('fluentbit-fluent-bit')"
fluentbit-restrict-selinux-type-exception:
  metadata:
    namespace: kyverno
    labels:
      app: fluentbit
  spec:
    policyRefs:
    - name: restrict-selinux-type
      kind: ValidatingPolicy
    matchConditions:
    - name: match-fluentbit
      expression: "object.metadata.namespace == 'fluentbit' && object.metadata.name.startsWith('fluentbit-fluent-bit')"
fluentbit-restrict-volume-types-exception:
  metadata:
    namespace: kyverno
    labels:
      app: fluentbit
  spec:
    policyRefs:
    - name: restrict-volume-types
      kind: ValidatingPolicy
    matchConditions:
    - name: match-fluentbit
      expression: "object.metadata.namespace == 'fluentbit' && object.metadata.name.startsWith('fluentbit-fluent-bit')"
{{- end }}
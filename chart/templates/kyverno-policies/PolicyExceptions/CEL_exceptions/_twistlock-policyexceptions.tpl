{{- define "bigbang.policyexceptions.twistlock.cel" }}
twistlock-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
  spec:
    policyRefs:
    - name: add-default-capability-drop
      ruleNames:
      - add-default-capability-drop
    matchConditions:
    - name: match-twistlock-resources
      expression: "object.metadata.namespace == 'twistlock' && (object.metadata.name.startsWith('twistlock-console') || object.metadata.name.startsWith('twistlock-defender-ds') || object.metadata.name.startsWith('volume-upgrade'))"
twistlock-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
  spec:
    policyRefs:
    - name: add-default-securitycontext
      kind: MutatingPolicy
    matchConditions:
    - name: match-twistlock-resources
      expression: "object.metadata.namespace == 'twistlock' && (object.metadata.name.startsWith('twistlock-console') || object.metadata.name.startsWith('twistlock-defender-ds') || object.metadata.name.startsWith('volume-upgrade-job'))"
twistlock-disallow-host-namespaces-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
  spec:
    policyRefs:
    - name: disallow-host-namespaces
      kind: ValidatingPolicy
    matchConditions:
    - name: match-twistlock-defender
      expression: "object.metadata.namespace == 'twistlock' && object.metadata.name.startsWith('twistlock-defender-ds')"
twistlock-disallow-tolerations-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
  spec:
    policyRefs:
    - name: disallow-tolerations
      kind: ValidatingPolicy
    matchConditions:
    - name: match-twistlock-defender
      expression: "object.metadata.namespace == 'twistlock' && object.metadata.name.startsWith('twistlock-defender-ds')"
twistlock-require-drop-all-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
  spec:
    policyRefs:
    - name: require-drop-all-capabilities
      kind: ValidatingPolicy
    matchConditions:
    - name: match-twistlock-resources
      expression: "object.metadata.namespace == 'twistlock' && (object.metadata.name.startsWith('twistlock-defender-ds') || object.metadata.name.startsWith('volume-upgrade'))"
twistlock-require-non-root-group-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
  spec:
    policyRefs:
    - name: require-non-root-group
      kind: ValidatingPolicy
    matchConditions:
    - name: match-twistlock-resources
      expression: "object.metadata.namespace == 'twistlock' && (object.metadata.name.startsWith('twistlock-defender-ds') || object.metadata.name.startsWith('volume-upgrade-job'))"
twistlock-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
  spec:
    policyRefs:
    - name: require-non-root-user
      kind: ValidatingPolicy
    matchConditions:
    - name: match-twistlock-resources
      expression: "object.metadata.namespace == 'twistlock' && (object.metadata.name.startsWith('twistlock-defender-ds') || object.metadata.name.startsWith('volume-upgrade-job'))"
twistlock-restrict-apparmor-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
  spec:
    policyRefs:
    - name: restrict-apparmor
      kind: ValidatingPolicy
    matchConditions:
    - name: match-twistlock-defender
      expression: "object.metadata.namespace == 'twistlock' && object.metadata.name.startsWith('twistlock-defender-ds')"
twistlock-restrict-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
  spec:
    policyRefs:
    - name: restrict-capabilities
      kind: ValidatingPolicy
    matchConditions:
    - name: match-twistlock-defender
      expression: "object.metadata.namespace == 'twistlock' && object.metadata.name.startsWith('twistlock-defender-ds')"
twistlock-restrict-host-path-mount-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
  spec:
    policyRefs:
    - name: restrict-host-path-mount
      kind: ValidatingPolicy
    matchConditions:
    - name: match-twistlock-defender
      expression: "object.metadata.namespace == 'twistlock' && object.metadata.name.startsWith('twistlock-defender-ds')"
twistlock-restrict-host-path-write-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
  spec:
    policyRefs:
    - name: restrict-host-path-write
      kind: ValidatingPolicy
    matchConditions:
    - name: match-twistlock-defender
      expression: "object.metadata.namespace == 'twistlock' && object.metadata.name.startsWith('twistlock-defender-ds')"
twistlock-restrict-selinux-type-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
  spec:
    policyRefs:
    - name: restrict-selinux-type
      kind: ValidatingPolicy
    matchConditions:
    - name: match-twistlock-defender
      expression: "object.metadata.namespace == 'twistlock' && object.metadata.name.startsWith('twistlock-defender-ds')"
twistlock-restrict-volume-types-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
  spec:
    policyRefs:
    - name: restrict-volume-types
      kind: ValidatingPolicy
    matchConditions:
    - name: match-twistlock-defender
      expression: "object.metadata.namespace == 'twistlock' && object.metadata.name.startsWith('twistlock-defender-ds')"
{{- end }}
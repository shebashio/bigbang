{{- define "bigbang.policyexceptions.neuvector.cel" }}
neuvector-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
  spec:
    policyRefs:
    - name: add-default-capability-drop
      kind: MutatingPolicy
    matchConditions:
    - name: match-neuvector-pods
      expression: "object.metadata.namespace == 'neuvector' && (object.metadata.name.startsWith('neuvector-enforcer-pod') || object.metadata.name.startsWith('neuvector-cert-upgrader-job') || object.metadata.name.startsWith('neuvector-controller-pod') || object.metadata.name.startsWith('neuvector-scanner-pod') || object.metadata.name.startsWith('neuvector-prometheus-exporter-pod'))"
neuvector-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
  spec:
    policyRefs:
    - name: add-default-securitycontext
      kind: MutatingPolicy
    matchConditions:
    - name: match-neuvector-pods
      expression: "object.metadata.namespace == 'neuvector' && (object.metadata.name.startsWith('neuvector-enforcer-pod-') || object.metadata.name.startsWith('neuvector-controller-pod-') || object.metadata.name.startsWith('neuvector-cert-upgrader-job-'))"
neuvector-disallow-host-namespaces-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
  spec:
    policyRefs:
    - name: disallow-host-namespaces
      kind: ValidatingPolicy
    matchConditions:
    - name: match-neuvector-enforcer
      expression: "object.metadata.namespace == 'neuvector' && object.metadata.name.startsWith('neuvector-enforcer-pod')"
neuvector-disallow-privileged-containers-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
  spec:
    policyRefs:
    - name: disallow-privileged-containers
      kind: ValidatingPolicy
    matchConditions:
    - name: match-neuvector-pods
      expression: "object.metadata.namespace == 'neuvector' && (object.metadata.name.startsWith('neuvector-enforcer-pod') || object.metadata.name.startsWith('neuvector-controller-pod') || object.metadata.name.startsWith('neuvector-scanner-pod'))"
neuvector-require-drop-all-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
  spec:
    policyRefs:
    - name: require-drop-all-capabilities
      kind: ValidatingPolicy
    matchConditions:
    - name: match-neuvector-pods
      expression: "object.metadata.namespace == 'neuvector' && (object.metadata.name.startsWith('neuvector-enforcer-pod') || object.metadata.name.startsWith('neuvector-cert-upgrader-job-') || object.metadata.name.startsWith('neuvector-controller-pod') || object.metadata.name.startsWith('neuvector-scanner-pod') || object.metadata.name.startsWith('neuvector-prometheus-exporter-pod'))"
neuvector-require-non-root-group-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
  spec:
    policyRefs:
    - name: require-non-root-group
      kind: ValidatingPolicy
    matchConditions:
    - name: match-neuvector-pods
      expression: "object.metadata.namespace == 'neuvector' && (object.metadata.name.startsWith('neuvector-enforcer-pod-') || object.metadata.name.startsWith('neuvector-controller-pod-') || object.metadata.name.startsWith('neuvector-cert-upgrader-job-'))"
neuvector-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
  spec:
    policyRefs:
    - name: require-non-root-user
      kind: ValidatingPolicy
    matchConditions:
    - name: match-neuvector
      expression: "object.metadata.namespace == 'neuvector' && object.metadata.name.startsWith('neuvector')"
neuvector-restrict-host-path-mount-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
  spec:
    policyRefs:
    - name: restrict-host-path-mount
      kind: ValidatingPolicy
    matchConditions:
    - name: match-neuvector-pods
      expression: "object.metadata.namespace == 'neuvector' && (object.metadata.name.startsWith('neuvector-enforcer-pod') || object.metadata.name.startsWith('neuvector-cert-upgrader-job-') || object.metadata.name.startsWith('neuvector-controller-pod'))"
neuvector-restrict-host-path-write-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
  spec:
    policyRefs:
    - name: restrict-host-path-write
      kind: ValidatingPolicy
    matchConditions:
    - name: match-neuvector-pods
      expression: "object.metadata.namespace == 'neuvector' && (object.metadata.name.startsWith('neuvector-controller-pod') || object.metadata.name.startsWith('neuvector-enforcer-pod'))"
neuvector-restrict-volume-types-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
  spec:
    policyRefs:
    - name: restrict-volume-types
      kind: ValidatingPolicy
    matchConditions:
    - name: match-neuvector-pods
      expression: "object.metadata.namespace == 'neuvector' && (object.metadata.name.startsWith('neuvector-controller-pod') || object.metadata.name.startsWith('neuvector-enforcer-pod'))"
{{- end }}
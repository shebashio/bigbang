{{- /*
Kyverno PolicyExceptions for NeuVector workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.neuvector" -}}
{{- if .Values.neuvector.enabled }}
# NeuVector needs host access to inspect network traffic / scan the node and
# container runtime, so its pods cannot meet the restricted Pod Security policies.
neuvector-require-drop-all-capabilities:
  spec:
    policyRefs:
      - name: require-drop-all-capabilities
        kind: ValidatingPolicy
    matchConditions:
      - name: neuvector-workloads
        expression: >-
          (object.metadata.namespace == 'neuvector' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-enforcer-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-cert-upgrader-job') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-controller-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-scanner-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-prometheus-exporter-pod')
          ))
neuvector-disallow-host-namespaces:
  spec:
    policyRefs:
      - name: disallow-host-namespaces
        kind: ValidatingPolicy
    matchConditions:
      - name: neuvector-enforcer
        expression: >-
          (object.metadata.namespace == 'neuvector' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-enforcer-pod'))
neuvector-disallow-privileged-containers:
  spec:
    policyRefs:
      - name: disallow-privileged-containers
        kind: ValidatingPolicy
    matchConditions:
      - name: neuvector-workloads
        expression: >-
          (object.metadata.namespace == 'neuvector' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-enforcer-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-controller-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-scanner-pod')
          ))
neuvector-require-non-root-group:
  spec:
    policyRefs:
      - name: require-non-root-group
        kind: ValidatingPolicy
    matchConditions:
      - name: neuvector-workloads
        expression: >-
          (object.metadata.namespace == 'neuvector' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-enforcer-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-controller-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-cert-upgrader-job')
          ))
neuvector-require-non-root-user:
  spec:
    policyRefs:
      - name: require-non-root-user
        kind: ValidatingPolicy
    matchConditions:
      - name: neuvector-workloads
        expression: >-
          (object.metadata.namespace == 'neuvector' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector'))
neuvector-restrict-host-path-mount:
  spec:
    policyRefs:
      - name: restrict-host-path-mount
        kind: ValidatingPolicy
    matchConditions:
      - name: neuvector-workloads
        expression: >-
          (object.metadata.namespace == 'neuvector' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-enforcer-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-cert-upgrader-job') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-controller-pod')
          ))
neuvector-restrict-host-path-write:
  spec:
    policyRefs:
      - name: restrict-host-path-write
        kind: ValidatingPolicy
    matchConditions:
      - name: neuvector-workloads
        expression: >-
          (object.metadata.namespace == 'neuvector' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-controller-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-enforcer-pod')
          ))
neuvector-restrict-volume-types:
  spec:
    policyRefs:
      - name: restrict-volume-types
        kind: ValidatingPolicy
    matchConditions:
      - name: neuvector-workloads
        expression: >-
          (object.metadata.namespace == 'neuvector' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-enforcer-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-controller-pod')
          ))
neuvector-add-default-capability-drop:
  spec:
    policyRefs:
      - name: add-default-capability-drop
        kind: MutatingPolicy
    matchConditions:
      - name: neuvector-workloads
        expression: >-
          (object.metadata.namespace == 'neuvector' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-enforcer-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-cert-upgrader-job') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-controller-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-scanner-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-prometheus-exporter-pod')
          ))
neuvector-add-default-securitycontext:
  spec:
    policyRefs:
      - name: add-default-securitycontext
        kind: MutatingPolicy
    matchConditions:
      - name: neuvector-workloads
        expression: >-
          (object.metadata.namespace == 'neuvector' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-enforcer-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-controller-pod') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('neuvector-cert-upgrader-job')
          ))
{{- end }}
{{- end -}}

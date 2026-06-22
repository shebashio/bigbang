{{- /*
Kyverno PolicyExceptions for Fluent Bit workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.fluentbit" -}}
{{- if .Values.fluentbit.enabled }}
# Fluent Bit needs privileged host access (journald, /var/log, container logs)
# to tail node and container logs, so it cannot meet the restricted policies.
fluentbit-fluent-bit:
  spec:
    policyRefs:
      - name: disallow-privileged-containers
        kind: ValidatingPolicy
      - name: require-non-root-group
        kind: ValidatingPolicy
      - name: require-non-root-user
        kind: ValidatingPolicy
      - name: restrict-host-path-mount
        kind: ValidatingPolicy
      - name: restrict-selinux-type
        kind: ValidatingPolicy
      - name: restrict-volume-types
        kind: ValidatingPolicy
    matchConditions:
      - name: fluentbit
        expression: >-
          (object.metadata.namespace == 'fluentbit' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('fluentbit-fluent-bit'))
fluentbit-add-default-securitycontext:
  spec:
    policyRefs:
      - name: add-default-securitycontext
        kind: MutatingPolicy
    matchConditions:
      - name: fluentbit
        expression: >-
          (object.metadata.namespace == 'fluentbit' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('fluentbit-fluent-bit'))
{{- end }}
{{- end -}}

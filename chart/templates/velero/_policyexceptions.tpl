{{- /*
Kyverno PolicyExceptions for Velero workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.velero" -}}
{{- $deployNodeAgent := (and .Values.addons.velero.enabled (dig "deployNodeAgent" false .Values.addons.velero.values)) }}
{{- if .Values.addons.velero.enabled }}
# The backup/restore test pod requires elevated capabilities to validate backups.
velero-require-drop-all-capabilities:
  spec:
    policyRefs:
      - name: require-drop-all-capabilities
        kind: ValidatingPolicy
    matchConditions:
      - name: velero-backup-restore-test
        expression: >-
          (object.metadata.namespace == 'velero' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('velero-backup-restore-test'))
velero-add-default-capability-drop:
  spec:
    policyRefs:
      - name: add-default-capability-drop
        kind: MutatingPolicy
    matchConditions:
      - name: velero-backup-restore-test
        expression: >-
          (object.metadata.namespace == 'velero' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('velero-backup-restore-test'))
{{- end }}
{{- if $deployNodeAgent }}
# The node-agent backup tool needs root access to the host's pod runtime
# directory mounted into the velero/node-agent pods.
velero-node-agent:
  spec:
    policyRefs:
      - name: require-non-root-group
        kind: ValidatingPolicy
      - name: require-non-root-user
        kind: ValidatingPolicy
      - name: restrict-host-path-mount
        kind: ValidatingPolicy
      - name: restrict-volume-types
        kind: ValidatingPolicy
    matchConditions:
      - name: velero-node-agent
        expression: >-
          (object.metadata.namespace == 'velero' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('node-agent'))
velero-node-agent-add-default-securitycontext:
  spec:
    policyRefs:
      - name: add-default-securitycontext
        kind: MutatingPolicy
    matchConditions:
      - name: velero-node-agent
        expression: >-
          (object.metadata.namespace == 'velero' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('node-agent'))
{{- end }}
{{- end -}}

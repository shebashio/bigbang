{{- /*
Kyverno PolicyExceptions for Twistlock (Prisma Cloud Defender) workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.twistlock" -}}
{{- if .Values.twistlock.enabled }}
# Twistlock Defenders run privileged on every node for real-time scanning
# (logs, /etc/passwd, container runtime socket, iptables), so they need broad
# carve-outs from the restricted Pod Security policies.
twistlock-defender-ds:
  spec:
    policyRefs:
      - name: disallow-host-namespaces
        kind: ValidatingPolicy
      - name: restrict-apparmor
        kind: ValidatingPolicy
      - name: restrict-capabilities
        kind: ValidatingPolicy
      - name: restrict-host-path-mount
        kind: ValidatingPolicy
      - name: restrict-host-path-write
        kind: ValidatingPolicy
      - name: restrict-selinux-type
        kind: ValidatingPolicy
      - name: restrict-volume-types
        kind: ValidatingPolicy
    matchConditions:
      - name: twistlock-defender
        expression: >-
          (object.metadata.namespace == 'twistlock' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('twistlock-defender-ds'))
twistlock-require-drop-all-capabilities:
  spec:
    policyRefs:
      - name: require-drop-all-capabilities
        kind: ValidatingPolicy
    matchConditions:
      - name: twistlock-workloads
        expression: >-
          (object.metadata.namespace == 'twistlock' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('twistlock-defender-ds') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('volume-upgrade')
          ))
twistlock-require-non-root:
  spec:
    policyRefs:
      - name: require-non-root-group
        kind: ValidatingPolicy
      - name: require-non-root-user
        kind: ValidatingPolicy
    matchConditions:
      - name: twistlock-workloads
        expression: >-
          (object.metadata.namespace == 'twistlock' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('twistlock-defender-ds') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('volume-upgrade-job')
          ))
twistlock-add-default-capability-drop:
  spec:
    policyRefs:
      - name: add-default-capability-drop
        kind: MutatingPolicy
    matchConditions:
      - name: twistlock-workloads
        expression: >-
          (object.metadata.namespace == 'twistlock' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('twistlock-console') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('twistlock-defender-ds') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('volume-upgrade')
          ))
twistlock-add-default-securitycontext:
  spec:
    policyRefs:
      - name: add-default-securitycontext
        kind: MutatingPolicy
    matchConditions:
      - name: twistlock-workloads
        expression: >-
          (object.metadata.namespace == 'twistlock' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('twistlock-console') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('twistlock-defender-ds') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('volume-upgrade-job')
          ))
{{- end }}
{{- end -}}

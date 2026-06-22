{{- /*
Kyverno PolicyExceptions for GitLab Runner workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.gitlabRunner" -}}
{{- if .Values.addons.gitlabRunner.enabled }}
# CI jobs spawned by the runner may require root access.
gitlab-runner:
  spec:
    policyRefs:
      - name: require-drop-all-capabilities
        kind: ValidatingPolicy
      - name: require-non-root-group
        kind: ValidatingPolicy
      - name: require-non-root-user
        kind: ValidatingPolicy
    matchConditions:
      - name: gitlab-runner
        expression: >-
          (object.metadata.namespace == 'gitlab-runner' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('runner-'))
gitlab-runner-add-default-capability-drop:
  spec:
    policyRefs:
      - name: add-default-capability-drop
        kind: MutatingPolicy
    matchConditions:
      - name: gitlab-runner
        expression: >-
          (object.metadata.namespace == 'gitlab-runner' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('runner'))
gitlab-runner-add-default-securitycontext:
  spec:
    policyRefs:
      - name: add-default-securitycontext
        kind: MutatingPolicy
    matchConditions:
      - name: gitlab-runner
        expression: >-
          (object.metadata.namespace == 'gitlab-runner' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('runner-'))
{{- end }}
{{- end -}}

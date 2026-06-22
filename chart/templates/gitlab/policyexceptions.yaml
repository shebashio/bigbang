{{- /*
Kyverno PolicyExceptions for GitLab workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.gitlab" -}}
{{- if .Values.addons.gitlab.enabled }}
# The GitLab webservice test-runner job requires elevated capabilities.
gitlab-require-drop-all-capabilities:
  spec:
    policyRefs:
      - name: require-drop-all-capabilities
        kind: ValidatingPolicy
    matchConditions:
      - name: gitlab-webservice-test-runner
        expression: >-
          (object.metadata.namespace == 'gitlab' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('webservice-test-runner'))
gitlab-add-default-capability-drop:
  spec:
    policyRefs:
      - name: add-default-capability-drop
        kind: MutatingPolicy
    matchConditions:
      - name: gitlab-webservice-test-runner
        expression: >-
          (object.metadata.namespace == 'gitlab' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('webservice-test-runner'))
{{- end }}
{{- end -}}

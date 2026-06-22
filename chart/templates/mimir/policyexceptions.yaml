{{- /*
Kyverno PolicyExceptions for Mimir workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.mimir" -}}
{{- if .Values.addons.mimir.enabled }}
# The Mimir smoke-test job requires elevated capabilities.
mimir-require-drop-all-capabilities:
  spec:
    policyRefs:
      - name: require-drop-all-capabilities
        kind: ValidatingPolicy
    matchConditions:
      - name: mimir-smoke-test
        expression: >-
          (object.metadata.namespace == 'mimir' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('mimir-mimir-smoke-test'))
mimir-add-default-capability-drop:
  spec:
    policyRefs:
      - name: add-default-capability-drop
        kind: MutatingPolicy
    matchConditions:
      - name: mimir-smoke-test
        expression: >-
          (object.metadata.namespace == 'mimir' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('mimir-mimir-smoke-test'))
{{- end }}
{{- end -}}

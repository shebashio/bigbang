{{- /*
Kyverno PolicyExceptions for Istiod.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.istiod" -}}
{{- if .Values.istiod.enabled }}
# istiod runs with a root group.
istiod-require-non-root-group:
  spec:
    policyRefs:
      - name: require-non-root-group
        kind: ValidatingPolicy
    matchConditions:
      - name: istiod
        expression: >-
          (object.metadata.namespace == 'istio-system' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('istiod'))
{{- end }}
{{- end -}}

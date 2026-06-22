{{- /*
Kyverno PolicyExceptions for Thanos workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.thanos" -}}
{{- if .Values.addons.thanos.enabled }}
# The Thanos compactor needs its API token.
thanos-compactor-auto-mount:
  spec:
    policyRefs:
      - name: disallow-auto-mount-service-account-token
        kind: ValidatingPolicy
    matchConditions:
      - name: thanos-compactor
        expression: >-
          (object.metadata.namespace == 'thanos' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('thanos-compactor'))
{{- end }}
{{- end -}}

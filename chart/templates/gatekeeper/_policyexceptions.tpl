{{- /*
Kyverno PolicyExceptions for Gatekeeper workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.gatekeeper" -}}
{{- if .Values.gatekeeper.enabled }}
# Gatekeeper's audit and controller-manager pods need their API token.
gatekeeper-auto-mount:
  spec:
    policyRefs:
      - name: disallow-auto-mount-service-account-token
        kind: ValidatingPolicy
    matchConditions:
      - name: gatekeeper
        expression: >-
          (object.metadata.namespace == 'gatekeeper-system' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('gatekeeper-audit') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('gatekeeper-controller-manager')
          ))
{{- end }}
{{- end -}}

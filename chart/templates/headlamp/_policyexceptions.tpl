{{- /*
Kyverno PolicyExceptions for Headlamp workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.headlamp" -}}
{{- if .Values.packages.headlamp.enabled }}
# Headlamp needs its API token to interact with the cluster.
headlamp-auto-mount:
  spec:
    policyRefs:
      - name: disallow-auto-mount-service-account-token
        kind: ValidatingPolicy
    matchConditions:
      - name: headlamp
        expression: >-
          (object.metadata.namespace == 'headlamp' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('headlamp'))
{{- end }}
{{- end -}}

{{- /*
Kyverno PolicyExceptions for External Secrets Operator workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.externalSecrets" -}}
{{- if .Values.addons.externalSecrets.enabled }}
# External Secrets needs its API token to reconcile secrets.
external-secrets-auto-mount:
  spec:
    policyRefs:
      - name: disallow-auto-mount-service-account-token
        kind: ValidatingPolicy
      - name: disallow-auto-mount-service-account-token-serviceaccounts
        kind: ValidatingPolicy
    matchConditions:
      - name: external-secrets
        expression: >-
          (object.metadata.namespace == 'external-secrets' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('external-secrets'))
{{- end }}
{{- end -}}

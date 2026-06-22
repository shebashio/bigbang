{{- /*
Kyverno PolicyExceptions for Vault workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.vault" -}}
{{- if .Values.addons.vault.enabled }}
# The Vault init job requires elevated capabilities.
vault-add-default-capability-drop:
  spec:
    policyRefs:
      - name: add-default-capability-drop
        kind: MutatingPolicy
    matchConditions:
      - name: vault-job-init
        expression: >-
          (object.metadata.namespace == 'vault' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('vault-vault-job-init'))
{{- end }}
{{- end -}}

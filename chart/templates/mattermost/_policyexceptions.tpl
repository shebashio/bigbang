{{- /*
Kyverno PolicyExceptions for Mattermost workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.mattermost" -}}
{{- if .Values.addons.mattermost.enabled }}
# Mattermost fails the default securityContext mutation; carve it out in both the
# mattermost and mattermost-operator namespaces.
mattermost-add-default-securitycontext:
  spec:
    policyRefs:
      - name: add-default-securitycontext
        kind: MutatingPolicy
    matchConditions:
      - name: mattermost
        expression: >-
          ((object.metadata.namespace == 'mattermost' || object.metadata.namespace == 'mattermost-operator') && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('mattermost-'))
{{- end }}
{{- end -}}

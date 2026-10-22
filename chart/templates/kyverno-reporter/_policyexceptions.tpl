{{- /*
Kyverno PolicyExceptions for Kyverno Reporter (Policy Reporter) workloads.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.kyvernoReporter" -}}
{{- if eq (include "packageEnabled" (dict "root" . "name" "kyvernoReporter")) "true" }}
# Kyverno Reporter needs its API token to read policy reports.
kyverno-reporter-auto-mount:
  spec:
    policyRefs:
      - name: disallow-auto-mount-service-account-token
        kind: ValidatingPolicy
    matchConditions:
      - name: kyverno-reporter
        expression: >-
          (object.metadata.namespace == 'kyverno-reporter' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).matches('^(policy-reporter|kyverno-reporter)(-.*)?$'))
{{- end }}
{{- end -}}

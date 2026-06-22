{{- /*
Kyverno PolicyExceptions for Istio ambient-mode ztunnel.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.ztunnel" -}}
{{- if eq (include "ambientEnabled" .) "true" }}
# Ztunnel (Istio ambient mode) requires elevated privileges for network
# management and host path access to function as a node-level proxy.
ztunnel:
  metadata:
    annotations:
      policies.kyverno.io/title: Ztunnel Policy Exception
      policies.kyverno.io/category: Istio
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: >-
        Ztunnel (Istio ambient mode) requires elevated privileges for network
        management and host path access to function as a node-level proxy.
  spec:
    policyRefs:
      - name: disallow-privilege-escalation
        kind: ValidatingPolicy
      - name: require-non-root-user
        kind: ValidatingPolicy
      - name: restrict-capabilities
        kind: ValidatingPolicy
      - name: restrict-host-path-mount
        kind: ValidatingPolicy
      - name: restrict-host-path-write
        kind: ValidatingPolicy
      - name: restrict-volume-types
        kind: ValidatingPolicy
    matchConditions:
      - name: ztunnel
        expression: >-
          (object.metadata.namespace == 'istio-system' && object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('ztunnel'))
{{- end }}
{{- end -}}

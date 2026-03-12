{{- define "bigbang.policyexceptions.headlamp" }}

---
  apiVersion: kyverno.io/v2
  kind: PolicyException
  metadata:
    annotations:
    labels:
      app: headlamp
    name: headlamp-disallow-auto-mount-service-account-token-exception
    namespace: {{ .Release.Namespace }}
  spec:
    exceptions:
    - policyName: disallow-auto-mount-service-account-token
      ruleNames:
      - disallow-auto-mount-service-account-token
    match:
      any:
      - resources:
          names:
          - headlamp*
          namespaces:
          - headlamp
{{- end }}
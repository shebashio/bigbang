{{- define "bigbang.policyexceptions.thanos" }}
  apiVersion: kyverno.io/v2
  kind: PolicyException
  metadata:
    annotations:
    labels:
      app: thanos
    name: thanos-disallow-auto-mount-service-account-token-exception
    namespace: {{ .Release.Namespace }}
  spec:
    exceptions:
    - policyName: disallow-auto-mount-service-account-token
      ruleNames:
      - disallow-auto-mount-service-account-token
    match:
      any:
      - resources:
          kinds:
          - Pod
          - Deployment
          - StatefulSet
          names:
          - thanos-compactor*
          namespaces:
          - thanos
{{- end }}
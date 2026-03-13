{{- define "bigbang.policyexceptions.thanos" }}
thanos-disallow-auto-mount-service-account-token-exception:
  metadata:
    labels:
      app: thanos
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
{{- define "bigbang.policyexceptions.kyvernoreporter" }}
kyvernoreporter-disallow-auto-mount-service-account-token-exception:
  metadata:
		namespace: kyverno
    labels:
      app: kyvernoreporter
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
          names:
          - kyverno-reporter*
          namespaces:
          - kyverno-reporter
{{- end }}
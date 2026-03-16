{{- define "bigbang.policyexceptions.headlamp" }}
headlamp-disallow-auto-mount-service-account-token-exception:
  metadata:
		namespace: kyverno
    labels:
      app: headlamp
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
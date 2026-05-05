{{- define "bigbang.policyexceptions.externalsecrets" }}
externalsecrets-disallow-auto-mount-service-account-token-exception:
  metadata:
    namespace: kyverno
    labels:
      app: external-secrets
    annotations:
      policies.kyverno.io/title: External Secrets disallow-auto-mount-service-account-token exception
      policies.kyverno.io/category: External Secrets
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: External Secrets requires automounting service account tokens to access Kubernetes APIs.
  spec:
    exceptions:
    - policyName: disallow-auto-mount-service-account-token
      ruleNames:
      - disallow-auto-mount-service-account-token
    match:
      any:
      - resources:
          names:
          - external-secrets*
          namespaces:
          - external-secrets
{{- end }}

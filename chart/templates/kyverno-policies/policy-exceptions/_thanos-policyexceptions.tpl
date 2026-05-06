{{- define "bigbang.policyexceptions.thanos" }}
thanos-disallow-auto-mount-service-account-token-exception:
  metadata:
    namespace: kyverno
    labels:
      app: thanos
    annotations:
      policies.kyverno.io/title: Thanos disallow-auto-mount-service-account-token exception
      policies.kyverno.io/category: Thanos
      policies.kyverno.io/subject: Pod, Deployment, StatefulSet
      policies.kyverno.io/description: "Thanos requires automounting of service account"
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
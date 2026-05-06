{{- define "bigbang.policyexceptions.kyvernoreporter" }}
kyvernoreporter-disallow-auto-mount-service-account-token-exception:
  metadata:
    namespace: kyverno
    labels:
      app: kyvernoreporter
    annotations:
      policies.kyverno.io/title: Kyverno Reporter disallow-auto-mount-service-account-token exception
      policies.kyverno.io/category: Kyverno Reporter
      policies.kyverno.io/subject: Pod, Deployment, ReplicaSet, ServiceAccount
      policies.kyverno.io/description: "Prevent Automounting of Kubernetes API Credentials on Pods and Service Accounts"
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
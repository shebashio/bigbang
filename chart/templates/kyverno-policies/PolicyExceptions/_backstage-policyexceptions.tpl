{{- define "bigbang.policyexceptions.backstage" }}
backstage-disallow-auto-mount-service-account-token-exception:
    metadata:
    namespace: kyverno
    labels:
      app: backstage
    annotations:
      policies.kyverno.io/title: Backstage disallow-auto-mount-service-account-token exception
      policies.kyverno.io/category: Backstage
      policies.kyverno.io/subject: Pod, Deployment, ReplicaSet, ServiceAccount
      policies.kyverno.io/description: "Backstage requires automounting of service account tokens for its backend to function"
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
                - ReplicaSet
                - ServiceAccount
                names:
                - backstage
                - backstage*
                namespaces:
                - backstage
{{- end }}
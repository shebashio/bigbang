gatekeeper-disallow-auto-mount-service-account-token-exception:
  metadata:
    labels:
      app: gatekeeper
    annotations:
      policies.kyverno.io/title: Gatekeeper disallow-auto-mount-service-account-token exception
      policies.kyverno.io/category: Gatekeeper 
      policies.kyverno.io/subject: Pod, Deployment
      policies.kyverno.io/description: "Gatekeeper requires automounting of service account tokens for its audit and controller-manager components to function"
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
          - gatekeeper-audit*
          - gatekeeper-controller-manager*
          namespaces:
          - gatekeeper-system
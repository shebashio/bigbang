gatekeeper-disallow-auto-mount-service-account-token-exception:
  metadata:
    labels:
      app: gatekeeper
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
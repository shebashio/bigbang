{{- define "bigbang.policyexceptions.backstage" }}
backstage-disallow-auto-mount-service-account-token-exception:
    metadata:
    namespace: kyverno
        labels:
            app: backstage
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
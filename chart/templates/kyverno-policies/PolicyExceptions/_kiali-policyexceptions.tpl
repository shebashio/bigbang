{{- define "bigbang.policyexceptions.kiali" }}
kiali-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: kiali
    annotations:
      policies.kyverno.io/title: Kiali require-non-root-user exception
      policies.kyverno.io/category: Kiali
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: Kiali needs this exception for the operator to deploy the Kiali server.
  spec:
    exceptions:
    - policyName: require-non-root-user
      ruleNames:
      - non-root-user
    match:
      any:
      - resources:
          names:
          - kiali-*
          namespaces:
          - kiali
{{- end }}

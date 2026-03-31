{{- define "bigbang.policyexceptions.ztunnel" }}
ztunnel-disallow-privilege-escalation-exception:
  metadata:
    namespace: kyverno
    labels:
      app: ztunnel
    annotations:
      policies.kyverno.io/title: Ztunnel Policy Exception
      policies.kyverno.io/category: Istio
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: >-
        Ztunnel (Istio ambient mode) requires elevated privileges for network
        management and host path access to function as a node-level proxy.
    spec:
      exceptions:
      - policyName: disallow-privilege-escalation
        ruleNames:
        - disallow-privilege-escalation
      - policyName: require-non-root-user
        ruleNames:
        - non-root-user
      - policyName: restrict-capabilities
        ruleNames:
        - capabilities
      - policyName: restrict-host-path-mount
        ruleNames:
        - restrict-hostpath-dirs
      - policyName: restrict-host-path-write
        ruleNames:
        - require-readonly-hostpath
      - policyName: restrict-volume-types
        ruleNames:
        - restrict-volume-types
      match:
        any:
        - resources:
            kinds:
            - Pod
            namespaces:
            - istio-system
            names:
            - "ztunnel-*"
{{- end }}
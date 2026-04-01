
{{- define "bigbang.policyexceptions.misc" }}
kube-system-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: kube
    annotations:
      policies.kyverno.io/title: Kube-system add-default-securitycontext exception
      policies.kyverno.io/category: Kube-system
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Kube-system requires access to journalctl as well"
  spec:
    exceptions:
    - policyName: add-default-securitycontext
      ruleNames:
      - add-default-securitycontext
    match:
      any:
      - resources:
          namespaces:
          - kube-system
kube-system-require-non-root-group-exception:
  metadata:
    namespace: kyverno
    labels:
      app: kube
    annotations:
      policies.kyverno.io/title: Kube-system require-non-root-group exception
      policies.kyverno.io/category: Kube-system
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Kube-system requires access to journalctl as well"
  spec:
    exceptions:
    - policyName: require-non-root-group
      ruleNames:
      - non-root-group
    match:
      any:
      - resources:
          namespaces:
          - kube-system
kube-system-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: kube
    annotations:
      policies.kyverno.io/title: Kube-system require-non-root-user exception
      policies.kyverno.io/category: Kube-system
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Kube-system requires access to journalctl as well"
  spec:
    exceptions:
    - policyName: require-non-root-user
      ruleNames:
      - non-root-user
    match:
      any:
      - resources:
          namespaces:
          - kube-system
require-istio-on-namespaces-exception:
  metadata:
    namespace: kyverno
    labels:
      app: kube
    annotations:
      policies.kyverno.io/title: Require Istio on Namespaces exception
      policies.kyverno.io/category: Kube-system
      policies.kyverno.io/subject: Namespace
      policies.kyverno.io/description: "
      - The Namespaces listed in this exception are required to run without Istio sidecar injection. This is because:
      - Kuberentes control plane does not use Istio
      - No pods in bigbang / default
      - Flux is installed prior to Istio
      - Istio does not inject itself
      "
  spec:
    exceptions:
    - policyName: require-istio-on-namespaces
      ruleNames:
      - istio-on-namespace
    match:
      any:
      - resources:
          namespaces:
          - kube-node-lease
          - kube-public
          - kube-system
          - bigbang
          - default
          - flux-system
          - istio-system
          - istio-gateway
{{- end }}
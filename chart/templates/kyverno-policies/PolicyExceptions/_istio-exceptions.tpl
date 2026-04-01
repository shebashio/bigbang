{{- define "bigbang.policyexceptions.istio" }}
istio-disallow-istio-injection-bypass-exception:
  metadata:
    namespace: kyverno
    labels:
      app: istio
    annotations:
      policies.kyverno.io/title: disallow-istio-injection-bypass-exception
      policies.kyverno.io/category: Istio
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Istio does not inject itself"
  spec:
    exceptions:
    - policyName: disallow-istio-injection-bypass
      ruleNames:
      - istio-on-pods
    match:
      any:
      - resources:
          namespaces:
          - istio-system
          - istio-gateway
istio-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: istio
    annotations:
      policies.kyverno.io/title: require-non-root-user-exception
      policies.kyverno.io/category: Istio
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Istio requires elevated privileges for network management and host path access to function as a node-level proxy."
  spec:
    exceptions:
    - policyName: require-non-root-user
      ruleNames:
      - non-root-user
    match:
      any:
      - resources:
          kinds:
          - Pods/containers
          names:
          - istio-init
istiod-require-non-root-group-exception:
  metadata:
    namespace: kyverno
    labels:
      app: istio
    annotations:
      policies.kyverno.io/title: require-non-root-group-exception
      policies.kyverno.io/category: Istio
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Istiod requires elevated privileges for network management"
  spec:
    exceptions:
    - policyName: require-non-root-group
      ruleNames:
      - run-as-group
      - fs-group
    match:
      any:
      - resources:
          names:
          - istiod*
          namespaces:
          - istio-system
istio-gateway-disallow-image-tags-exception: 
  metadata:
    namespace: kyverno
    labels:
      app: istio
    annotations:
        policies.kyverno.io/title: disallow-image-tags-exception
        policies.kyverno.io/category: Istio
        policies.kyverno.io/subject: Pod
        policies.kyverno.io/description: "istio/gateway sets the deployment image to `auto` by default
      # and does not expose any way for the chart consumer to modify
      # it. The idea is `istiod` will inject the correct image at
      # pod creation based on `istiod`'s proxy config."
  spec:
    exceptions:
    - policyName: disallow-image-tags
      ruleNames:
      - disallow-image-tags
    match:
      any:
      - resources:
          names:
          - '*-ingressgateway'
          - '*-egressgateway'
          namespaces:
          - istio-gateway
istio-gateway-restrict-image-registries-exception:
  metadata:
    namespace: kyverno
    labels:
      app: istio
    annotations:
      policies.kyverno.io/title: restrict-image-registries-exception
      policies.kyverno.io/category: Istio
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "istio/gateway sets the deployment image to `auto` by default
      # and does not expose any way for the chart consumer to modify
      # it. The idea is `istiod` will inject the correct image at
      # pod creation based on `istiod`'s proxy config."
  spec:
    exceptions:
    - policyName: restrict-image-registries
      ruleNames:
      - restrict-image-registries
    match:
      any:
      - resources:
          names:
          - '*-ingressgateway'
          - '*-egressgateway'
          namespaces:
          - istio-gateway

{{- end }}
{{- define "bigbang.policyexceptions.istio" }}
istio-disallow-istio-injection-bypass-exception:
  metadata:
    labels:
      app: istio
  spec:
    exceptions:
    - policyName: disallow-istio-injection-bypass
      ruleNames:
      - disallow-istio-injection-bypass
    match:
      any:
      - resources:
          namespaces:
          - istio-system
          - istio-gateway
istio-require-non-root-user-exception:
  metadata:
    labels:
      app: istio
    namespace: {{ .Release.Namespace }}
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
    labels:
      app: istio
  spec:
    exceptions:
    - policyName: require-non-root-group
      ruleNames:
      - require-non-root-group
    match:
      any:
      - resources:
          names:
          - istiod*
          namespaces:
          - istio-system
istio-gateway-disallow-image-tags-exception: 
  metadata:
    labels:
      app: istio
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
    labels:
      app: istio
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
require-istio-on-namespaces-exception:
  metadata:
    labels:
      app: istio
      otherapps: "flux/kube-system/default/bigbang"
  spec:
    exceptions:
    - policyName: require-istio-on-namespaces
      ruleNames:
      - require-istio-on-namespaces
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
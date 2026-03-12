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
istiod-require-non-root-group-exception:
  metadata:
    labels:
      app: istiod
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
{{- end }}
{{- if and ((.Values.istiod).enabled) ((.Values.istioGateway).enabled) }}
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




#exceptions that existed prioir to conversion of exclusions to exceptions
{{- if .Values.istiod.enabled }}
apiVersion:  kyverno.io/v2
metadata:
  name: require-non-root-user-exception
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
---
apiVersion:  kyverno.io/v2
metadata:
  name: istio-require-non-root-group-exception
  namespace: {{ .Release.Namespace }}
spec:
  exceptions:
  - policyName: require-non-root-group
    ruleNames:
    - run-as-group
  match:
    any:
    - resources:
        kinds:
        - Pods/containers
        names:
        - istio-init
---

{{- end }}

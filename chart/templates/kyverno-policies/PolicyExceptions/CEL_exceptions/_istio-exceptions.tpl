{{- define "bigbang.policyexceptions.istio.cel" }}
istio-disallow-istio-injection-bypass-exception:
  metadata:
    namespace: kyverno
    labels:
      app: istio
  spec:
    policyRefs:
    - name: disallow-istio-injection-bypass
      ruleNames:
      - disallow-istio-injection-bypass
    matchConditions:
    - name: match-istio-namespaces
      expression: "object.metadata.namespace in ['istio-system', 'istio-gateway']"
istio-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: istio
  spec:
    policyRefs:
    - name: require-non-root-user
      ruleNames:
      - non-root-user
    matchConditions:
    - name: match-istio-init
      expression: "object.metadata.name == 'istio-init'"
istiod-require-non-root-group-exception:
  metadata:
    namespace: kyverno
    labels:
      app: istio
  spec:
    policyRefs:
    - name: require-non-root-group
      kind: ValidatingPolicy
    matchConditions:
    - name: match-istiod
      expression: "object.metadata.namespace == 'istio-system' && object.metadata.name.startsWith('istiod')"
istio-gateway-disallow-image-tags-exception:
  metadata:
    namespace: kyverno
    labels:
      app: istio
  spec:
    policyRefs:
    - name: disallow-image-tags
      kind: ValidatingPolicy
    matchConditions:
    - name: match-istio-gateways
      expression: "object.metadata.namespace == 'istio-gateway' && (object.metadata.name.endsWith('-ingressgateway') || object.metadata.name.endsWith('-egressgateway'))"
istio-gateway-restrict-image-registries-exception:
  metadata:
    namespace: kyverno
    labels:
      app: istio
  spec:
    policyRefs:
    - name: restrict-image-registries
      kind: ValidatingPolicy
    matchConditions:
    - name: match-istio-gateways
      expression: "object.metadata.namespace == 'istio-gateway' && (object.metadata.name.endsWith('-ingressgateway') || object.metadata.name.endsWith('-egressgateway'))"
require-istio-on-namespaces-exception:
  metadata:
    namespace: kyverno
    labels:
      app: istio
      otherapps: "flux/kube-system/default/bigbang"
  spec:
    policyRefs:
    - name: require-istio-on-namespaces
      kind: ValidatingPolicy
    matchConditions:
    - name: match-system-namespaces
      expression: "object.metadata.namespace in ['kube-node-lease', 'kube-public', 'kube-system', 'bigbang', 'default', 'flux-system', 'istio-system', 'istio-gateway']"
{{- end }}
{{- define "bigbang.policyexceptions.istio" }}

apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: istio
  name: istio-disallow-istio-injection-bypass-exception
  namespace: {{ .Release.Namespace }}
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
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: istiod
  name: istiod-require-non-root-group-exception
  namespace: {{ .Release.Namespace }}
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
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: istio
  name: istio-gateway-disallow-image-tags-exception
  namespace: {{ .Release.Namespace }}
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
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: istio
  name: istio-gateway-restrict-image-registries-exception
  namespace: {{ .Release.Namespace }}
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
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: istio
    otherapps: "flux/kube-system/default/bigbang"
  name: require-istio-on-namespaces-exception
  namespace: {{ .Release.Namespace }}
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
kind: PolicyException
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
kind: PolicyException
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

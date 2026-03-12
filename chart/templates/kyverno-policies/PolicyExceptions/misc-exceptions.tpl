
{{- define "bigbang.policyexceptions.misc" }}

apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: kube
  name: kube-system-add-default-securitycontext-exception
  namespace: {{ .Release.Namespace }}
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
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: kube
  name: kube-system-require-non-root-group-exception
  namespace: {{ .Release.Namespace }}
spec:
  exceptions:
  - policyName: require-non-root-group
    ruleNames:
    - require-non-root-group
  match:
    any:
    - resources:
        namespaces:
        - kube-system
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: kube
  name: kube-system-require-non-root-user-exception
  namespace: {{ .Release.Namespace }}
spec:
  exceptions:
  - policyName: require-non-root-user
    ruleNames:
    - require-non-root-user
  match:
    any:
    - resources:
        namespaces:
        - kube-system
{{- end }}
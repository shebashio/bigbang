
{{- define "bigbang.policyexceptions.misc" }}
kube-system-add-default-securitycontext-exception:
  metadata:
		namespace: kyverno
    labels:
      app: kube
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
kube-system-require-non-root-user-exception:
  metadata:
		namespace: kyverno
    labels:
      app: kube
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
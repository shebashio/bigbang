
{{- define "bigbang.policyexceptions.gitlab" }}
gitlab-add-default-capability-drop-exception:
  metadata:
		namespace: kyverno
    labels:
      app: gitlab
  spec:
    exceptions:
    - policyName: add-default-capability-drop
      ruleNames:
      - add-default-capability-drop
    match:
      any:
      - resources:
          names:
          - webservice-test-runner*
          namespaces:
          - gitlab
gitlab-require-drop-all-capabilities-exception:
  metadata:
		namespace: kyverno
    labels:
      app: gitlab
  spec:
    exceptions:
    - policyName: require-drop-all-capabilities
      ruleNames:
      - require-drop-all-capabilities
    match:
      any:
      - resources:
          names:
          - webservice-test-runner-*
          namespaces:
          - gitlab
gitlabrunner-add-default-capability-drop-exception:
  metadata:
		namespace: kyverno
    labels:
      app: gitlabrunner
  spec:
    exceptions:
    - policyName: add-default-capability-drop
      ruleNames:
      - add-default-capability-drop
    match:
      any:
      - resources:
          names:
          - runner*
          namespaces:
          - gitlab-runner
{{- end }}
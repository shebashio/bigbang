{{- define "bigbang.policyexceptions.gitlabrunner" }}
gitlabrunner-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlabrunner
  spec:
    exceptions:
    - policyName: add-default-securitycontext
      ruleNames:
      - add-default-securitycontext
    match:
      any:
      - resources:
          names:
          - runner-*
          namespaces:
          - gitlab-runner
gitlabrunner-require-drop-all-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlabrunner
  spec:
    exceptions:
    - policyName: require-drop-all-capabilities
      ruleNames:
      - require-drop-all-capabilities
    match:
      any:
      - resources:
          names:
          - runner-*
          namespaces:
          - gitlab-runner
gitlabrunner-require-non-root-group-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlabrunner
  spec:
    exceptions:
    - policyName: require-non-root-group
      ruleNames:
      - require-non-root-group
    match:
      any:
      - resources:
          names:
          - runner-*
          namespaces:
          - gitlab-runner
gitlabrunner-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlabrunner
  spec:
    exceptions:
    - policyName: require-non-root-user
      ruleNames:
      - require-non-root-user
    match:
      any:
      - resources:
          names:
          - runner-*
          namespaces:
          - gitlab-runner
{{- end }}
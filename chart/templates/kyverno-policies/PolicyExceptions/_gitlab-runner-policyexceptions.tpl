{{- define "bigbang.policyexceptions.gitlabrunner" }}
gitlabrunner-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlabrunner
    annotations:
      policies.kyverno.io/title: GitLab Runner add-default-securitycontext exception
      policies.kyverno.io/category: GitLab Runner
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "For GitLab runner CI jobs that require root access"
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
    annotations:
      policies.kyverno.io/title: GitLab Runner require-drop-all-capabilities exception
      policies.kyverno.io/category: GitLab Runner
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "For GitLab runner CI jobs that require root access"
  spec:
    exceptions:
    - policyName: require-drop-all-capabilities
      ruleNames:
      - drop-all-capabilities
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
    annotations:
      policies.kyverno.io/title: GitLab Runner require-non-root-group exception
      policies.kyverno.io/category: GitLab Runner
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "For GitLab runner CI jobs that require root access"
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
          - runner-*
          namespaces:
          - gitlab-runner
gitlabrunner-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlabrunner
    annotations:
      policies.kyverno.io/title: GitLab Runner require-non-root-user exception
      policies.kyverno.io/category: GitLab Runner
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "For GitLab runner CI jobs that require root access"
  spec:
    exceptions:
    - policyName: require-non-root-user
      ruleNames:
      - non-root-user
    match:
      any:
      - resources:
          names:
          - runner-*
          namespaces:
          - gitlab-runner
{{- end }}
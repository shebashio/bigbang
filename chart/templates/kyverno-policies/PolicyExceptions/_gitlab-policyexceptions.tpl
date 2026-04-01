
{{- define "bigbang.policyexceptions.gitlab" }}
gitlab-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlab
    annotations:
      policies.kyverno.io/title: GitLab add-default-capability-drop exception
      policies.kyverno.io/category: GitLab
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "For GitLab runner CI jobs that require root access"
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
    annotations:
      policies.kyverno.io/title: GitLab require-drop-all-capabilities exception
      policies.kyverno.io/category: GitLab
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
          - webservice-test-runner-*
          namespaces:
          - gitlab
gitlabrunner-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlabrunner
    annotations:
      policies.kyverno.io/title: GitLab Runner add-default-capability-drop exception
      policies.kyverno.io/category: GitLab Runner
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "For GitLab runner CI jobs that require root access"
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
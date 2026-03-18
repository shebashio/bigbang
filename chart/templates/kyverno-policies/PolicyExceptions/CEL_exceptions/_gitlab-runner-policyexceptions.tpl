{{- define "bigbang.policyexceptions.gitlabrunner.cel" }}
gitlabrunner-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlabrunner
  spec:
    policyRefs:
    - name: add-default-securitycontext
      ruleNames:
      - add-default-securitycontext
    matchConditions:
    - name: match-runner
      expression: "object.metadata.namespace == 'gitlab-runner' && object.metadata.name.startsWith('runner-')"
gitlabrunner-require-drop-all-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlabrunner
  spec:
    policyRefs:
    - name: require-drop-all-capabilities
      ruleNames:
      - require-drop-all-capabilities
    matchConditions:
    - name: match-runner
      expression: "object.metadata.namespace == 'gitlab-runner' && object.metadata.name.startsWith('runner-')"
gitlabrunner-require-non-root-group-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlabrunner
  spec:
    policyRefs:
    - name: require-non-root-group
      kind: ValidatingPolicy
    matchConditions:
    - name: match-runner
      expression: "object.metadata.namespace == 'gitlab-runner' && object.metadata.name.startsWith('runner-')"
gitlabrunner-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlabrunner
  spec:
    policyRefs:
    - name: require-non-root-user
      kind: ValidatingPolicy
    matchConditions:
    - name: match-runner
      expression: "object.metadata.namespace == 'gitlab-runner' && object.metadata.name.startsWith('runner-')"
{{- end }}
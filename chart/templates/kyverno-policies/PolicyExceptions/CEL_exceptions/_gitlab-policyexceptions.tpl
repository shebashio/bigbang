
{{- define "bigbang.policyexceptions.gitlab.cel" }}
gitlab-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlab
  spec:
    policyRefs:
    - name: add-default-capability-drop
      kind: MutatingPolicy
    matchConditions:
    - name: match-webservice-test-runner
      expression: "object.metadata.namespace == 'gitlab' && object.metadata.name.startsWith('webservice-test-runner')"
gitlab-require-drop-all-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlab
  spec:
    policyRefs:
    - name: require-drop-all-capabilities
      kind: ValidatingPolicy
    matchConditions:
    - name: match-webservice-test-runner
      expression: "object.metadata.namespace == 'gitlab' && object.metadata.name.startsWith('webservice-test-runner-')"
gitlabrunner-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: gitlabrunner
  spec:
    policyRefs:
    - name: add-default-capability-drop
      kind: MutatingPolicy
    matchConditions:
    - name: match-runner
      expression: "object.metadata.namespace == 'gitlab-runner' && object.metadata.name.startsWith('runner')"
{{- end }}
{{- define "bigbang.policyexceptions.cypress" }}

cypress-restrict-volume-types-exception:
  metadata:
    namespace: kyverno
    labels:
      app: cypress
    annotations:
      description: "Allows gluon cypress test pods to mount volumes"
  spec:
    exceptions:
    - policyName: restrict-volume-types
      ruleNames:
      - restrict-volume-types
    match:
      any:
      - resources:
          names:
          - cypress-*
cypress-restrict-host-path-mount-exception:
  metadata:
    namespace: kyverno
    labels:
      app: cypress
    annotations:
      description: "Allows gluon cypress test pods to mount volumes"
  spec:
    exceptions:
    - policyName: restrict-host-path-mount
      ruleNames:
      - restrict-host-path-mount
    match:
      any:
      - resources:
          names:
          - cypress-*
          namespaces:
          - anchore
          - backstage
          - bbctl
          - gitlab
          - gitlab-runner
          - kiali
          - cluster-auditor
          - mattermost
          - nexus-repository-manager
          - keycloak
          - kyverno-reporter
          - mimir
          - monitoring
          - vault
          - logging
          - twistlock
          - sonarqube
          - logging
          - tempo
          - argocd
          - minio
          - minio-operator
          - neuvector
          - harbor
          - fortify
          - thanos
          - alloy
          - headlamp
        # parameters:
        #   allow:
        #   - /tmp/allowed
cypress-restrict-host-path-write-exception:
  metadata:
    namespace: kyverno
    labels: 
      app: cypress
    annotations:
      description: "Allows gluon cypress test pods to mount volumes"
  spec:
    exceptions:
    - policyName: restrict-host-path-write
      ruleNames:
      - restrict-host-path-write
    match:
      any:
      - resources:
          names:
          - cypress-*
          namespaces:
          - anchore
          - backstage
          - bbctl
          - gitlab
          - gitlab-runner
          - kiali
          - cluster-auditor
          - mattermost
          - nexus-repository-manager
          - keycloak
          - kyverno-reporter
          - mimir
          - monitoring
          - vault
          - logging
          - twistlock
          - sonarqube
          - logging
          - tempo
          - argocd
          - minio
          - minio-operator
          - neuvector
          - harbor
          - fortify
          - thanos
          - alloy
          - headlamp
{{- end }}
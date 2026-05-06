{{- define "bigbang.policyexceptions.monitoring" }}
monitoring-disallow-auto-mount-service-account-token-exception:
  metadata:
    namespace: kyverno
    labels:
      app: monitoring
    annotations:
      policies.kyverno.io/title: Monitoring disallow-auto-mount-service-account-token exception
      policies.kyverno.io/category: Monitoring
      policies.kyverno.io/subject: Pod, Deployment, StatefulSet
      policies.kyverno.io/description: "Thanos requires automounting of service account"
  spec:
    exceptions:
    - policyName: disallow-auto-mount-service-account-token
      ruleNames:
      - disallow-auto-mount-service-account-token
    match:
      any:
      - resources:
          kinds:
          - Pod
          - Deployment
          - StatefulSet
          names:
          - notification-controller*
          - helm-controller*
          - source-controller*
          - kustomize-controller*
          namespaces:
          - flux-system
monitoring-disallow-tolerations-exception:
  metadata:
    namespace: kyverno
    labels:
      app: monitoring
    annotations:
      policies.kyverno.io/title: Monitoring disallow-tolerations exception
      policies.kyverno.io/category: Monitoring
      policies.kyverno.io/subject: Pod, Deployment, StatefulSet
      policies.kyverno.io/description: "Prometheus Node Exporter needs to be able to run on all nodes, regardless of taint, to gather node metrics"
  spec:
    exceptions:
    - policyName: disallow-tolerations
      ruleNames: ["*"]
    match:
      any:
      - resources:
          names:
          - monitoring-monitoring-prometheus-node-exporter*
          namespaces:
          - monitoring
monitoring-restrict-host-path-mount-exception:
  metadata:
    namespace: kyverno
    labels:
      app: monitoring
    annotations:
      policies.kyverno.io/title: Monitoring restrict-host-path-mount exception
      policies.kyverno.io/category: Monitoring
      policies.kyverno.io/subject: Pod, Deployment, StatefulSet
      policies.kyverno.io/description: "      # Prometheus Node Exporter mounts the following hostPaths:
      # - `/`: monitor disk usage on filesystem mounts using e2fs call
      # - `/proc` and `/sys`: gather node metrics
      # Since mounting the root would expose sensitive information, it is better to
      # exlcude Prometheus Node Exporter than add the paths as allowable mounts"
  spec:
    exceptions:
    - policyName: restrict-host-path-mount
      ruleNames:
      - restrict-hostpath-dirs
    match:
      any:
      - resources:
          names:
          - monitoring-monitoring-prometheus-node-exporter*
          namespaces:
          - monitoring
monitoring-restrict-volume-types-exception:
  metadata:
    namespace: kyverno
    labels:
      app: monitoring
    annotations:
      policies.kyverno.io/title: Monitoring restrict-volume-types exception
      policies.kyverno.io/category: Monitoring
      policies.kyverno.io/subject: Pod, Deployment, StatefulSet
      policies.kyverno.io/description: "      # Prometheus Node Exporter mounts the following hostPaths:
      # - `/`: monitor disk usage on filesystem mounts using e2fs call
      # - `/proc` and `/sys`: gather node metrics
      # Since mounting the root would expose sensitive information, it is better to
      # exlcude Prometheus Node Exporter than add the paths as allowable mounts"
  spec:
    exceptions:
    - policyName: restrict-volume-types
      ruleNames:
      - restrict-volume-types
    match:
      any:
      - resources:
          names:
          - monitoring-monitoring-prometheus-node-exporter*
          namespaces:
          - monitoring
{{- end }}
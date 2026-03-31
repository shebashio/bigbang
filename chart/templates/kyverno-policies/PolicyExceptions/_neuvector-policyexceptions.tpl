{{- define "bigbang.policyexceptions.neuvector" }}
neuvector-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
    annotations:
      policies.kyverno.io/description: "Neuvector needs access to host to inspect network traffic"
  spec:
    exceptions:
    - policyName: add-default-capability-drop
      ruleNames:
      - add-default-capability-drop
    match:
      any:
      - resources:
          names:
          - neuvector-enforcer-pod*
          - neuvector-cert-upgrader-job*
          - neuvector-controller-pod*
          - neuvector-scanner-pod*
          - neuvector-prometheus-exporter-pod*
          namespaces:
          - neuvector
neuvector-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
    annotations:
      policies.kyverno.io/description: "Neuvector needs access to host to inspect network traffic"
  spec:
    exceptions:
    - policyName: add-default-securitycontext
      ruleNames:
      - add-default-securitycontext
    match:
      any:
      - resources:
          names:
          - neuvector-enforcer-pod-*
          - neuvector-controller-pod-*
          - neuvector-cert-upgrader-job-*
          namespaces:
          - neuvector
neuvector-disallow-host-namespaces-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
    annotations:
      policies.kyverno.io/description: "Neuvector needs access to host to inspect network traffic"
  spec:
    exceptions:
    - policyName: disallow-host-namespaces
      ruleNames:
      - disallow-host-namespaces
    match:
      any:
      - resources:
          names:
          - neuvector-enforcer-pod*
          namespaces:
          - neuvector
neuvector-disallow-privileged-containers-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
    annotations:
      policies.kyverno.io/description: "Neuvector needs privileged access for realtime scanning of files from the node / access to the container runtime"
  spec:
    exceptions:
    - policyName: disallow-privileged-containers
      ruleNames:
      - disallow-privileged-containers
    match:
      any:
      - resources:
          names:
          - neuvector-enforcer-pod*
          - neuvector-controller-pod*
          - neuvector-scanner-pod*
          namespaces:
          - neuvector
neuvector-require-drop-all-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
    annotations:
      policies.kyverno.io/description: "Neuvector needs access to host to inspect network traffic"
  spec:
    exceptions:
    - policyName: require-drop-all-capabilities
      ruleNames:
      - require-drop-all-capabilities
    match:
      any:
      - resources:
          names:
          - neuvector-enforcer-pod*
          - neuvector-cert-upgrader-job-*
          - neuvector-controller-pod*
          - neuvector-scanner-pod*
          - neuvector-prometheus-exporter-pod*
          namespaces:
          - neuvector
neuvector-require-non-root-group-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
    annotations:
      policies.kyverno.io/description: "Neuvector needs access to host to inspect network traffic"
  spec:
    exceptions:
    - policyName: require-non-root-group
      ruleNames:
      - require-non-root-group
    match:
      any:
      - resources:
          names:
          - neuvector-enforcer-pod-*
          - neuvector-controller-pod-*
          - neuvector-cert-upgrader-job-*
          namespaces:
          - neuvector
neuvector-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
    annotations:
      policies.kyverno.io/description: "Neuvector needs access to host to inspect network traffic"
  spec:
    exceptions:
    - policyName: require-non-root-user
      ruleNames:
      - require-non-root-user
    match:
      any:
      - resources:
          names:
          - neuvector*
          namespaces:
          - neuvector
neuvector-restrict-host-path-mount-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
    annotations:
      policies.kyverno.io/description: "      # Neuvector mounts the following hostPaths:
      # `/var/neuvector`: for Neuvector's buffering and persistent state
      # `/var/run`: communication to docker daemon
      # `/proc`: monitoring of proccesses for malicious activity
      # `/sys/fs/cgroup`: important files the controller wants to monitor for malicious content"
  spec:
    exceptions:
    - policyName: restrict-host-path-mount
      ruleNames:
      - restrict-host-path-mount
    match:
      any:
      - resources:
          names:
          - neuvector-enforcer-pod*
          - neuvector-cert-upgrader-job-*
          - neuvector-controller-pod*
          namespaces:
          - neuvector
neuvector-restrict-host-path-write-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
    annotations:
      policies.kyverno.io/description: "      # Neuvector mounts the following hostPaths:
      # `/var/neuvector`: for Neuvector's buffering and persistent state
      # `/var/run`: communication to docker daemon
      # `/proc`: monitoring of proccesses for malicious activity
      # `/sys/fs/cgroup`: important files the controller wants to monitor for malicious content"
  spec:
    exceptions:
    - policyName: restrict-host-path-write
      ruleNames:
      - restrict-host-path-write
    match:
      any:
      - resources:
          names:
          - neuvector-controller-pod*
          - neuvector-enforcer-pod*
          namespaces:
          - neuvector
neuvector-restrict-volume-types-exception:
  metadata:
    namespace: kyverno
    labels:
      app: neuvector
    annotations:
      policies.kyverno.io/description: "      # Neuvector mounts the following hostPaths:
      # `/var/neuvector`: for Neuvector's buffering and persistent state
      # `/var/run`: communication to docker daemon
      # `/proc`: monitoring of proccesses for malicious activity
      # `/sys/fs/cgroup`: important files the controller wants to monitor for malicious content"
  spec:
    exceptions:
    - policyName: restrict-volume-types
      ruleNames:
      - restrict-volume-types
    match:
      any:
      - resources:
          names:
          - neuvector-controller-pod*
          - neuvector-enforcer-pod*
          namespaces:
          - neuvector
{{- end }}
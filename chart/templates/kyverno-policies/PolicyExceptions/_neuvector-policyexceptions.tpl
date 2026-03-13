{{- define "bigbang.policyexceptions.neuvector" }}
neuvector-add-default-capability-drop-exception:
  metadata:
    labels:
      app: neuvector
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
    labels:
      app: neuvector
    name: neuvector-add-default-securitycontext-exception
    namespace: {{ .Release.Namespace }}
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
    labels:
      app: neuvector
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
    labels:
      app: neuvector
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
    labels:
      app: neuvector
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
    labels:
      app: neuvector
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
    labels:
      app: neuvector
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
    labels:
      app: neuvector
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
    labels:
      app: neuvector
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
    labels:
      app: neuvector
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
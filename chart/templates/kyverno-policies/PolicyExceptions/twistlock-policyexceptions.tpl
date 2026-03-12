{{- define "bigbang.policyexceptions.twistlock" }}
twistlock-add-default-capability-drop-exception:
  metadata:
    labels:
      app: twistlock
  spec:
    exceptions:
    - policyName: add-default-capability-drop
      ruleNames:
      - add-default-capability-drop
    match:
      any:
      - resources:
          names:
          - twistlock-console*
          - twistlock-defender-ds*
          - volume-upgrade*
          namespaces:
          - twistlock
twistlock-add-default-securitycontext-exception:
  metadata:
    labels:
      app: twistlock
  spec:
    exceptions:
    - policyName: add-default-securitycontext
      ruleNames:
      - add-default-securitycontext
    match:
      any:
      - resources:
          names:
          - twistlock-console*
          - twistlock-defender-ds*
          - volume-upgrade-job*
          namespaces:
          - twistlock

twistlock-disallow-host-namespaces-exception:
  metadata:
    labels:
      app: twistlock
  spec:
    exceptions:
    - policyName: disallow-host-namespaces
      ruleNames:
      - disallow-host-namespaces
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-disallow-tolerations-exception:
  metadata:
    labels:
      app: twistlock
  spec:
    exceptions:
    - policyName: disallow-tolerations
      ruleNames:
      - disallow-tolerations
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-require-drop-all-capabilities-exception:
  metadata:
    labels:
      app: twistlock
  spec:
    exceptions:
    - policyName: require-drop-all-capabilities
      ruleNames:
      - require-drop-all-capabilities
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          - volume-upgrade*
          namespaces:
          - twistlock
twistlock-require-non-root-group-exception:
  metadata:
    labels:
      app: twistlock
  spec:
    exceptions:
    - policyName: require-non-root-group
      ruleNames:
      - require-non-root-group
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          - volume-upgrade-job*
          namespaces:
          - twistlock
twistlock-require-non-root-user-exception: kyverno.io/v2
  metadata:
    labels:
      app: twistlock
  spec:
    exceptions:
    - policyName: require-non-root-user
      ruleNames:
      - require-non-root-user
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          - volume-upgrade-job*
          namespaces:
          - twistlock
twistlock-restrict-apparmor-exception: 
  metadata:
    labels:
      app: twistlock
  spec:
    exceptions:
    - policyName: restrict-apparmor
      ruleNames:
      - restrict-apparmor
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-restrict-capabilities-exception:
  metadata:
    labels:
      app: twistlock
  spec:
    exceptions:
    - policyName: restrict-capabilities
      ruleNames:
      - restrict-capabilities
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-restrict-host-path-mount-exception:
  metadata:
    labels:
      app: twistlock
  spec:
    exceptions:
    - policyName: restrict-host-path-mount
      ruleNames:
      - restrict-host-path-mount
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-restrict-host-path-write-exception:
  metadata:
    labels:
      app: twistlock
  spec:
    exceptions:
    - policyName: restrict-host-path-write
      ruleNames:
      - restrict-host-path-write
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-restrict-selinux-type-exception:
  metadata:
    labels:
      app: twistlock
  spec:
    exceptions:
    - policyName: restrict-selinux-type
      ruleNames:
      - restrict-selinux-type
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-restrict-volume-types-exception:
  metadata:
    labels:
      app: twistlock
  spec:
    exceptions:
    - policyName: restrict-volume-types
      ruleNames:
      - restrict-volume-types
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
{{- end }}
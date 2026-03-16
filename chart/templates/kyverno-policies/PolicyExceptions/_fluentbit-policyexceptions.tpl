{{- define "bigbang.policyexceptions.fluentbit" }}
fluentbit-add-default-securitycontext-exception:
  metadata:
    labels:
      app: fluentbit
  spec:
  exceptions:
  - policyName: add-default-securitycontext
    ruleNames:
    - add-default-securitycontext
  match:
    any:
    - resources:
        names:
        - fluentbit-fluent-bit*
        namespaces:
        - fluentbit
fluentbit-disallow-privileged-containers-exception:
  metadata:
    labels:
      app: fluentbit
  spec:
    exceptions:
    - policyName: disallow-privileged-containers
      ruleNames:
      - disallow-privileged-containers
    match:
      any:
      - resources:
          names:
          - fluentbit-fluent-bit*
          namespaces:
          - fluentbit
fluentbit-disallow-tolerations-exception:
  metadata:
    labels:
      app: fluentbit
  spec:
    exceptions:
    - policyName: disallow-tolerations
      ruleNames:
      - disallow-tolerations
    match:
      any:
      - resources:
          names:
          - fluentbit-fluent-bit*
          namespaces:
          - fluentbit
fluentbit-require-non-root-group-exception:
  metadata:
    labels:
      app: fluentbit
  spec:
    exceptions:
    - policyName: require-non-root-group
      ruleNames:
      - require-non-root-group
    match:
      any:
      - resources:
          names:
          - fluentbit-fluent-bit*
          namespaces:
          - fluentbit
fluentbit-require-non-root-user-exception:
  metadata:
    labels:
      app: fluentbit
  spec:
    exceptions:
    - policyName: require-non-root-user
      ruleNames:
      - require-non-root-user
    match:
      any:
      - resources:
          names:
          - fluentbit-fluent-bit*
          namespaces:
          - fluentbit
fluentbit-restrict-host-path-mount-exception:
  metadata:
    labels:
      app: fluentbit
  spec:
    exceptions:
    - policyName: restrict-host-path-mount
      ruleNames:
      - restrict-host-path-mount
    match:
      any:
      - resources:
          names:
          - fluentbit-fluent-bit*
          namespaces:
          - fluentbit
fluentbit-restrict-selinux-type-exception:
  metadata:
    labels:
      app: fluentbit
    name: fluentbit-restrict-selinux-type-exception
    namespace: {{ .Release.Namespace }}
  spec:
    exceptions:
    - policyName: restrict-selinux-type
      ruleNames:
      - restrict-selinux-type
    match:
      any:
      - resources:
          names:
          - fluentbit-fluent-bit*
          namespaces:
          - fluentbit
fluentbit-restrict-volume-types-exception:
  metadata:
    labels:
      app: fluentbit
  spec:
    exceptions:
    - policyName: restrict-volume-types
      ruleNames:
      - restrict-volume-types
    match:
      any:
      - resources:
          names:
          - fluentbit-fluent-bit*
          namespaces:
          - fluentbit
{{- end }}
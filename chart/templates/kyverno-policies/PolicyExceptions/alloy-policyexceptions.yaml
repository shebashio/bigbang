{{- define "bigbang.policyexceptions.alloy" }}
alloy-add-default-securitycontext-exception:
  kind: PolicyException
  metadata:
    labels:
      app: alloy
    name: alloy-add-default-securitycontext-exception
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
          - alloy-alloy-logs*
          namespaces:
          - alloy
---
alloy-require-non-root-group-exception:
  kind: PolicyException
  metadata:
    labels:
      app: alloy
    namespace: {{ .Release.Namespace }}
  spec:
    exceptions:
    - policyName: require-non-root-group
      ruleNames:
      - require-non-root-group
    match:
      any:
      - resources:
          names:
          - alloy-alloy-logs*
          namespaces:
          - alloy
---
alloy-require-non-root-user-exception:
  kind: PolicyException
  metadata:
    labels:
      app: alloy
    namespace: {{ .Release.Namespace }}
  spec:
    exceptions:
    - policyName: require-non-root-user
      ruleNames:
      - require-non-root-user
    match:
      any:
      - resources:
          names:
          - alloy-alloy-logs*
          namespaces:
          - alloy
---
alloy-restrict-capabilities-exception:
  kind: PolicyException
  metadata:
    labels:
      app: alloy
    name: alloy-restrict-capabilities-exception
  namespace: {{ .Release.Namespace }}
  spec:
    exceptions:
    - policyName: restrict-capabilities
      ruleNames:
      - restrict-capabilities
    match:
      any:
      - resources:
          names:
          - alloy-alloy-metrics*
          - alloy-alloy-receiver*
          - alloy-alloy-logs*
          - alloy-alloy-singleton*
          namespaces:
          - alloy
---
alloy-restrict-host-path-mount-exception:
  kind: PolicyException
  metadata:
    labels:
      app: alloy
    name: alloy-restrict-host-path-mount-exception
    namespace: {{ .Release.Namespace }}
  spec:
    exceptions:
    - policyName: restrict-host-path-mount
    ruleNames:
    - restrict-host-path-mount
    match:
      any:
      - resources:
          names:
          - alloy-alloy-logs*
          namespaces:
          - alloy
---
alloy-restrict-selinux-type-exception:
  kind: PolicyException
  metadata:
    labels:
      app: alloy
    name: alloy-restrict-selinux-type-exception
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
          - alloy-alloy-logs-*
          namespaces:
          - alloy
---
alloy-restrict-volume-types-exception:
  kind: PolicyException
  metadata:
    labels:
      app: alloy
    name: alloy-restrict-volume-types-exception
    namespace: {{ .Release.Namespace }}
  spec:
    exceptions:
    - policyName: restrict-volume-types
      ruleNames:
      - restrict-volume-types
    match:
      any:
      - resources:
          names:
          - alloy-alloy-logs*
          namespaces:
          - alloy
{{- end }}
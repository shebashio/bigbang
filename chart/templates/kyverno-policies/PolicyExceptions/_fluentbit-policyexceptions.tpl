{{- define "bigbang.policyexceptions.fluentbit" }}
fluentbit-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: fluentbit
    annotations:
      policies.kyverno.io/title: Fluentbit-add-default-securitycontext-exception
      policies.kyverno.io/category: Fluentbit
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "# Fluentbit requires access to journalctl as well as /var/log.  This would require modifications
      # to the host operating system, creating a user, adding that user to the  systemd-journal user group
      # and then granting permissions recursively on /var/log."
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
    namespace: kyverno
    labels:
      app: fluentbit
    annotations:
      policies.kyverno.io/title: Fluentbit-disallow-privileged-containers-exception
      policies.kyverno.io/category: Fluentbit
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "# NEEDS FURTHER JUSTIFICATION
      Fluentbit needs privileged to read and store the buffer for tailing logs from the nodes"
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
    namespace: kyverno
    labels:
      app: fluentbit
    annotations:
      policies.kyverno.io/title: Fluentbit-disallow-tolerations-exception
      policies.kyverno.io/category: Fluentbit
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Fluent bit needs to be able to run on all nodes to gather logs from the host for containers"
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
    namespace: kyverno
    labels:
      app: fluentbit
    annotations:
      policies.kyverno.io/title: Fluentbit-require-non-root-group-exception
      policies.kyverno.io/category: Fluentbit
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Fluentbit requires access to journalctl as well as /var/log.  This would require modifications
      # to the host operating system, creating a user, adding that user to the  systemd-journal user group
      # and then granting permissions recursively on /var/log."
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
    namespace: kyverno
    labels:
      app: fluentbit
    annotations:
      policies.kyverno.io/title: Fluentbit-require-non-root-user-exception
      policies.kyverno.io/category: Fluentbit
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Fluentbit requires access to journalctl as well as /var/log.  This would require modifications
      # to the host operating system, creating a user, adding that user to the systemd-journal user group
      # and then granting permissions recursively on /var/log."
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
    namespace: kyverno
    labels:
      app: fluentbit
    annotations:
      policies.kyverno.io/title: Fluentbit-restrict-host-path-mount-exception
      policies.kyverno.io/category: Fluentbit
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "# Fluent Bit mounts the following hostPaths:
          # - `/var/log`: to tail node logs (e.g. journal) and pod logs
          # - `/var/lib/docker/containers`: to tail container logs
          # - `/etc/machine-id`: to obtain the node's unique machine ID for identifying systemd log folder
          # - `/var/log/flb-storage`: for Fluent Bit's buffering and persistent state
          # Since logs can have sensitive information, it is better to exclude
          # FluentBit from the policy than add the paths as allowable mounts"
  spec:
    exceptions:
    - policyName: restrict-host-path-mount
      ruleNames:
      - restrict-hostpath-dirs
    match:
      any:
      - resources:
          names:
          - fluentbit-fluent-bit*
          namespaces:
          - fluentbit
fluentbit-restrict-selinux-type-exception:
  metadata:
    namespace: kyverno
    labels:
      app: fluentbit
    annotations:
      policies.kyverno.io/title: Fluentbit-restrict-selinux-type-exception
      policies.kyverno.io/category: Fluentbit
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "# Fluent Bit mounts the following hostPaths:
          # - `/var/log`: to tail node logs (e.g. journal) and pod logs
          # - `/var/lib/docker/containers`: to tail container logs
          # - `/etc/machine-id`: to obtain the node's unique machine ID for identifying systemd log folder
          # - `/var/log/flb-storage`: for Fluent Bit's buffering and persistent state
          # Since logs can have sensitive information, it is better to exclude
          # FluentBit from the policy than add the paths as allowable mounts"
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
    namespace: kyverno
    labels:
      app: fluentbit
    annotations:
      policies.kyverno.io/title: Fluentbit-restrict-volume-types-exception
      policies.kyverno.io/category: Fluentbit
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "# Fluent bit containers requires HostPath volumes, to tail node and container logs.  It is also used for buffering
          # https://docs.fluentbit.io/manual/pipeline/filters/kubernetes#workflow-of-tail-+-kubernetes-filter"
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
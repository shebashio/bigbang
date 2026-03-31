{{- define "bigbang.policyexceptions.alloy" }}
alloy-add-default-securitycontext-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
    annotations:
      policies.kyverno.io/title: Allloy-add-default-securitycontext-exception
      policies.kyverno.io/category: Alloy
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Alloy requires access to journalctl as well as /var/log.  This would require modifications
       to the host operating system, creating a user, adding that user to the systemd-journal user group
       and then granting permissions recursively on /var/log."
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
alloy-require-non-root-group-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
    annotations:
      policies.kyverno.io/title: Allloy-require-non-root-group-exception
      policies.kyverno.io/category: Alloy
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Alloy requires access to journalctl as well as /var/log.  This would require modifications
       to the host operating system, creating a user, adding that user to the systemd-journal user group
       and then granting permissions recursively on /var/log."
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
alloy-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
    annotations:
      policies.kyverno.io/title: Allloy-require-non-root-user-exception
      policies.kyverno.io/category: Alloy
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Alloy requires access to journalctl as well as /var/log.  This would require modifications
       to the host operating system, creating a user, adding that user to the systemd-journal user group
       and then granting permissions recursively on /var/log."
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
alloy-restrict-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
    annotations:
      policies.kyverno.io/title: Allloy-restrict-capabilities-exception
      policies.kyverno.io/category: Alloy
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Alloy requires access to journalctl as well as /var/log.  This would require modifications
       to the host operating system, creating a user, adding that user to the systemd-journal user group
       and then granting permissions recursively on /var/log."
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
alloy-restrict-host-path-mount-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
    annotations:
      policies.kyverno.io/title: Allloy-restrict-host-path-mount-exception
      policies.kyverno.io/category: Alloy
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Alloy requires access to journalctl as well as /var/log.  This would require modifications
       to the host operating system, creating a user, adding that user to the systemd-journal user group
       and then granting permissions recursively on /var/log."
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
alloy-restrict-selinux-type-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
    annotations:
      policies.kyverno.io/title: Allloy-restrict-selinux-type-exception
      policies.kyverno.io/category: Alloy
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: " Alloy requires SELinux option type 'spc_t' for privileged host volume mounting on SELinux enabled systems
           Alloy mounts the following hostPaths:
           - `/var/log`: to tail node logs (e.g. journal) and pod logs
           - `/var/lib/docker/containers`: to tail container logs"
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
alloy-restrict-volume-types-exception:
  metadata:
    namespace: kyverno
    labels:
      app: alloy
    annotations:
      policies.kyverno.io/title: Allloy-restrict-volume-types-exception
      policies.kyverno.io/category: Alloy
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Alloy mounts the following hostPaths:
       - `/var/log`: to tail node logs (e.g. journal) and pod logs
       - `/var/lib/docker/containers`: to tail container logs"
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
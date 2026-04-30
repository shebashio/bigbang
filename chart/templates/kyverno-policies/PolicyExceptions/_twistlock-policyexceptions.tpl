{{- define "bigbang.policyexceptions.twistlock" }}
twistlock-add-default-capability-drop-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
    annotations:
      description: " # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
      # - read logs from `/var/log` to watch for malicious processes
      # - audit modifications to `/etc/passwd` (watching for suspicious changes)
      # - access the container runtime socket (observing all running containers on a node)"
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
    namespace: kyverno
    labels:
      app: twistlock
    annotations:
      description: " # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
      # - read logs from `/var/log` to watch for malicious processes
      # - audit modifications to `/etc/passwd` (watching for suspicious changes)
      # - access the container runtime socket (observing all running containers on a node)"
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
    namespace: kyverno
    labels:
      app: twistlock
    annotations:
      description: "      # Twistlock, by default, does its own network monitoring. hostNetworking is enabled by default for this purpose
      # With hostNetworking enabled, Istio sidecar injection is disabled. If this function is disabled, Twistlock will
      # not be able to self monitor. If both Istio sidecar injection and TL monitoring are disabled, a security gap will
      # be created for network monitoring in Twistlock.  So, it is important to make sure at least one is enabled."
  spec:
    exceptions:
    - policyName: disallow-host-namespaces
      ruleNames:
      - host-namespaces
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-disallow-tolerations-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
    annotations:
      description: " # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
      # - read logs from `/var/log` to watch for malicious processes
      # - audit modifications to `/etc/passwd` (watching for suspicious changes)
      # - access the container runtime socket (observing all running containers on a node)"
  spec:
    exceptions:
    - policyName: disallow-tolerations
      ruleNames: ["*"]
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-require-drop-all-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
    annotations:
      policies.kyverno.io/title: Twistlock require-drop-all-capabilities exception
      policies.kyverno.io/category: Twistlock
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: " # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
      # - read logs from `/var/log` to watch for malicious processes
      # - audit modifications to `/etc/passwd` (watching for suspicious changes)
      # - access the container runtime socket (observing all running containers on a node)"
  spec:
    exceptions:
    - policyName: require-drop-all-capabilities
      ruleNames:
      - drop-all-capabilities
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
    namespace: kyverno
    labels:
      app: twistlock
    annotations:
      policies.kyverno.io/title: Twistlock require-non-root-group exception
      policies.kyverno.io/category: Twistlock
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: " # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
      # - read logs from `/var/log` to watch for malicious processes
      # - audit modifications to `/etc/passwd` (watching for suspicious changes)
      # - access the container runtime socket (observing all running containers on a node)"
  spec:
    exceptions:
    - policyName: require-non-root-group
      ruleNames:
      - run-as-group
      - fs-group
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          - volume-upgrade-job*
          namespaces:
          - twistlock
twistlock-require-non-root-user-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
    annotations:
      policies.kyverno.io/title: Twistlock require-non-root-user exception
      policies.kyverno.io/category: Twistlock
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: " # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
      # - read logs from `/var/log` to watch for malicious processes
      # - audit modifications to `/etc/passwd` (watching for suspicious changes)
      # - access the container runtime socket (observing all running containers on a node)"
  spec:
    exceptions:
    - policyName: require-non-root-user
      ruleNames:
      - non-root-user
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
    namespace: kyverno
    labels:
      app: twistlock
    annotations:
      policies.kyverno.io/title: Twistlock restrict-apparmor exception
      policies.kyverno.io/category: Twistlock
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "Twistlock Defenders use an `unconfined` appArmor profile."
  spec:
    exceptions:
    - policyName: restrict-apparmor
      ruleNames:
      - app-armor
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-restrict-capabilities-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
    annotations:
      policies.kyverno.io/title: Twistlock restrict-capabilities exception
      policies.kyverno.io/category: Twistlock
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: "    # NEEDS FURTHER JUSTIFICATION
    # Twistlock Defenders require the following capabilities
    # - NET_ADMIN  - Process monitoring and Iptables
    # - NET_RAW    - Iptables (CNNF, runtime DNS, WAAS)  See https://bugzilla.redhat.com/show_bug.cgi?id=1895032
    # - SYS_ADMIN  - filesystem monitoring
    # - SYS_PTRACE - local audit monitoring
    # - SYS_CHROOT - changing mount namespace using setns
    # - MKNOD      - Create special files using mknod, used by docker-less registry scanning
    # - SETFCAP    - Set file capabilties, used by docker-less registry scanning
    # - IPC_LOCK
    "
  spec:
    exceptions:
    - policyName: restrict-capabilities
      ruleNames:
      - capabilities
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-restrict-host-path-mount-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
    annotations:
      policies.kyverno.io/title: Twistlock restrict-host-path-mount exception
      policies.kyverno.io/category: Twistlock
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: " # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
      # - read logs from `/var/log` to watch for malicious processes
      # - audit modifications to `/etc/passwd` (watching for suspicious changes)
      # - access the container runtime socket (observing all running containers on a node)"
  spec:
    exceptions:
    - policyName: restrict-host-path-mount
      ruleNames:
      - restrict-hostpath-dirs
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-restrict-host-path-write-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
    annotations:
      policies.kyverno.io/title: Twistlock restrict-host-path-write exception
      policies.kyverno.io/category: Twistlock
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: " # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
      # - read logs from `/var/log` to watch for malicious processes
      # - audit modifications to `/etc/passwd` (watching for suspicious changes)
      # - access the container runtime socket (observing all running containers on a node)"
  spec:
    exceptions:
    - policyName: restrict-host-path-write
      ruleNames:
      - require-readonly-hostpath
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-restrict-selinux-type-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
    annotations:
      policies.kyverno.io/title: Twistlock restrict-selinux-type exception
      policies.kyverno.io/category: Twistlock
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: " # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
      # - read logs from `/var/log` to watch for malicious processes
      # - audit modifications to `/etc/passwd` (watching for suspicious changes)
      # - access the container runtime socket (observing all running containers on a node)"
  spec:
    exceptions:
    - policyName: restrict-selinux-type
      ruleNames:
      - pod-selinux-options-type
      - container-selinux-options-type
    match:
      any:
      - resources:
          names:
          - twistlock-defender-ds*
          namespaces:
          - twistlock
twistlock-restrict-volume-types-exception:
  metadata:
    namespace: kyverno
    labels:
      app: twistlock
    annotations:
      policies.kyverno.io/title: Twistlock restrict-volume-types exception
      policies.kyverno.io/category: Twistlock
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: " # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
      # - read logs from `/var/log` to watch for malicious processes
      # - audit modifications to `/etc/passwd` (watching for suspicious changes)
      # - access the container runtime socket (observing all running containers on a node)"
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
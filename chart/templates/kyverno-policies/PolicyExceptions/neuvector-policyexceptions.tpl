{{- define "bigbang.policyexceptions.neuvector" }}
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: neuvector
  name: neuvector-add-default-capability-drop-exception
  namespace: {{ .Release.Namespace }}
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
---
apiVersion: kyverno.io/v2
kind: PolicyException
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
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: neuvector
  name: neuvector-disallow-host-namespaces-exception
  namespace: {{ .Release.Namespace }}
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
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: neuvector
  name: neuvector-disallow-privileged-containers-exception
  namespace: {{ .Release.Namespace }}
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
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: neuvector
  name: neuvector-require-drop-all-capabilities-exception
  namespace: {{ .Release.Namespace }}
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
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: neuvector
  name: neuvector-require-non-root-group-exception
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
        - neuvector-enforcer-pod-*
        - neuvector-controller-pod-*
        - neuvector-cert-upgrader-job-*
        namespaces:
        - neuvector
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: neuvector
  name: neuvector-require-non-root-user-exception
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
        - neuvector*
        namespaces:
        - neuvector
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: neuvector
  name: neuvector-restrict-host-path-mount-exception
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
        - neuvector-enforcer-pod*
        - neuvector-cert-upgrader-job-*
        - neuvector-controller-pod*
        namespaces:
        - neuvector
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: neuvector
  name: neuvector-restrict-host-path-write-exception
  namespace: {{ .Release.Namespace }}
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
---
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  labels:
    app: neuvector
  name: neuvector-restrict-volume-types-exception
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
        - neuvector-controller-pod*
        - neuvector-enforcer-pod*
        namespaces:
        - neuvector
{{- end }}
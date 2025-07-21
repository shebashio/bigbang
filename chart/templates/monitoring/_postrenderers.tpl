{{- define "monitoring.automountServiceAccountTokenPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /automountServiceAccountToken
            value: true
        target:
          kind: ServiceAccount
          name: kube-prometheus-stack-admission
{{- end }}

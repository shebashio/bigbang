{{- define "monitoring.automountServiceAccountTokenPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /automountServiceAccountToken
            value: true
        target:
          kind: ServiceAccount
          name: monitoring-admission
{{- end }}

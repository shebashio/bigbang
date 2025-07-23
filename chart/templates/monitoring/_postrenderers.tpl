{{- define "monitoring.automountServiceAccountTokenPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /automountServiceAccountToken
            value: true
        target:
          kind: ServiceAccount
          name: kube-prometheus-stack-admission
{{- end }}

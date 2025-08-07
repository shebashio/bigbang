{{- define "sonarqube.upstreamModificationPostRenders" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /metadata/annotations/helm.sh~1hook  # ~1 to escape the / in helm.sh/hook object
            value: post-install
        target:
          kind: Job
          name: sonarqube-sonarqube-change-admin-password-hook
{{- end }}
{{- define "sonarqube.istioPrometheusPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/ports/-
            value:
              name: monitoring-web
              port: 8000
              protocol: TCP
              targetPort: monitoring-web
          - op: add
            path: /spec/ports/-
            value:
              name: monitoring-ce
              port: 8001
              protocol: TCP
              targetPort: monitoring-ce
        target:
          kind: Service
          name: sonarqube-sonarqube
{{- end }}
{{- define "mimir.istioPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/ports/1/appProtocol
            value: tcp
        target:
          kind: Service
          name: .*-headless
{{- end }}

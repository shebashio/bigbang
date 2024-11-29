{{- define "mimir.istioPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/ports/1/appProtocol
            value: tcp
        target:
          kind: Service
          name: .*-headless$
      - patch: |
          - op: add
            path: /spec/ports/1/appProtocol
            value: grpc
        target:
          kind: Service
          name: ^.+-(?:alertmanager|compactor|distributor|ingester(-zone.*)?|overrides-exporter|querier|query-frontend|store-gateway(-zone.*))$
{{- end }}

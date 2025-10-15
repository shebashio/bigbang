{{- define "tempo.promPortsPostRenderers" }}
- kustomize:
    patches:
      - target:
          kind: Service
          name: .*tempo.*
        patch: |
          - op: add
            path: /spec/ports/2/appProtocol
            value: http
{{- end }}
{{- define "tempo.serviceMonitorPostRenderers" }}
- kustomize:
    patches:
      - target:
          kind: ServiceMonitor
          name: .*tempo.*
        patch: |
          - op: add
            path: /spec/endpoints/0/scheme
            value: https
          - op: add
            path: /spec/endpoints/0/tlsConfig
            value:
              caFile: /etc/prom-certs/root-cert.pem
              certFile: /etc/prom-certs/cert-chain.pem
              keyFile: /etc/prom-certs/key.pem
              insecureSkipVerify: true
          - op: remove
            path: /spec/endpoints/1
{{- end }}
{{- define "tempo.objectStoragePostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/template/spec/containers/0/envFrom
            value:
              - secretRef:
                  name: tempo-object-storage
        target:
          group: apps
          version: v1
          kind: StatefulSet
          name: ".*tempo.*"
{{- end }}
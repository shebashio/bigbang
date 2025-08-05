{{- define "tempo.promPortsPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /spec/ports/2/port
            value: 3100
          - op: replace
            path: /spec/ports/2/targetPort
            value: 3100
          - op: add
            path: /spec/ports/2/appProtocol
            value: http
        target:
          kind: Service
          name: .*tempo.*
      - patch: |
          - op: replace
            path: /spec/template/spec/containers/0/ports/0/containerPort
            value: 3100
        target:
          kind: StatefulSet
          name: .*tempo.*
{{- end }}
{{- define "tempo.serviceMonitorPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /spec/endpoints/2/scheme
            value: http
          - op: add
            path: /spec/endpoints/2/tlsConfig/caFile
            value: /etc/prom-certs/root-cert.pem
          - op: add
            path: /spec/endpoints/2/tlsConfig/certFile
            value:  /etc/prom-certs/cert-chain.pem
          - op: add
            path: /spec/endpoints/2/tlsConfig/keyFile
            value: /etc/prom-certs/key.pem
          - op: remove
            path: /spec/endpoints/1
        target:
          kind: ServiceMonitor
          name: .*tempo.*
{{- end }}
{{- define "tempo.objectStoragePostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/template/spec/containers/0/envFrom/secretRef/0/name
            value: tempo-object-storage
        target:
          kind: StatefulSet
          name: .*tempo.*
{{- end }}
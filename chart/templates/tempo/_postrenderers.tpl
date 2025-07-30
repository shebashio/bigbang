- kustomize:
    patches:
      {{- define "tempo.promPortsPostRenderers" }}
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
        name: {{Release.Name}}
#  - name: tempo-prom-metrics
#    port: 3100
#    protocol: TCP
#    targetPort: 3100
#    appProtocol: http
      {{- end }}
      {{- define "tempo.serviceMonitorPostRenderers" }}
      - patch: |
          - op: add
            path: /spec/endpoints/2/scheme
            value: http
          - op: remove
            path: /spec/endpoints/2/tlsConfig
            value: http
      target:
        kind: ServiceMonitor
        name: {{Release.Name}}
#  endpoints:
#   - scheme:
#   - tlsConfig:
#

      {{- end }}
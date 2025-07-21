{{- define "neuvector.ServiceMonitorPostRenderer" }}
    - kustomize:
        patches:
          - target:
              kind: ServiceMonitor
              name: neuvector-prometheus-exporter
              namespace: neuvector
            patch: |-
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
{{- end }}
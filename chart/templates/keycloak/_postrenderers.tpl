{{- define "keycloak.mtlsServiceMonitorPostrenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /spec/endpoints/0/tlsConfig
            value:
              caFile: /etc/prom-certs/root-cert.pem
              certFile: /etc/prom-certs/cert-chain.pem
              keyFile: /etc/prom-certs/key.pem
              insecureSkipVerify: true
        target:
          kind: ServiceMonitor
          name: .* # all ServiceMonitors
{{- end }}

{{/*
Patches the upstream garage-metrics Service to add appProtocol: http on the metrics port.

Without appProtocol, Istio generates a dual inbound filter chain (istio-http/* ALPN +
TCP catch-all). Prometheus connects with standard TLS ALPN (h2/http/1.1) which does not
match the istio-http/* chain and fails on the TCP catch-all with unexpected EOF.
Setting appProtocol: http produces a single HTTP connection manager inbound filter chain,
identical to how other BB packages expose their metrics ports under STRICT mTLS.

Applied whenever Istio is enabled and monitoring is enabled.
*/}}
{{- define "garage.metricsServicePostRenderer" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/ports/0/appProtocol
            value: http
        target:
          kind: Service
          name: ^garage-metrics$
{{- end }}

{{/*
Patches the upstream garage ServiceMonitor to set scheme: https and inject Istio
prom-certs into tlsConfig.

The upstream chart has an nindent 6 bug in its tlsConfig rendering that places fields
(caFile, certFile, keyFile, insecureSkipVerify) as siblings of tlsConfig at the endpoint
level rather than as children. The Prometheus Operator CRD rejects those fields at the
endpoint level, causing Helm upgrades to fail when tlsConfig is populated.

By patching the ServiceMonitor after render we bypass the upstream template entirely
and write a correctly nested tlsConfig directly into the rendered manifest.

Applied when Istio is enabled, ambient is not active, and mTLS mode is STRICT.
*/}}
{{- define "garage.serviceMonitorPostRenderer" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /spec/endpoints/0/scheme
            value: https
          - op: add
            path: /spec/endpoints/0/tlsConfig
            value:
              caFile: /etc/prom-certs/root-cert.pem
              certFile: /etc/prom-certs/cert-chain.pem
              keyFile: /etc/prom-certs/key.pem
              insecureSkipVerify: true
        target:
          kind: ServiceMonitor
          name: ^garage$
{{- end }}

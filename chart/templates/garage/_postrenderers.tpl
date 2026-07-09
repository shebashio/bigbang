{{/*
Patches the upstream garage metrics Service to add appProtocol: http.

Without appProtocol, Istio generates a dual inbound filter chain (istio-http/* ALPN +
TCP catch-all). Prometheus connects with standard TLS ALPN (h2/http/1.1) which does not
match the istio-http/* chain and fails on the TCP catch-all with unexpected EOF.
Setting appProtocol: http produces a single HTTP connection manager inbound filter chain.

Targets the upstream metrics Service by name suffix since the release name varies by
deployment. Applied when Istio is enabled and monitoring is enabled.
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
          name: ^.*-metrics$
{{- end }}

{{/*
Patches the upstream garage ServiceMonitor to set scheme: https and inject Istio
prom-certs into tlsConfig.

The upstream chart's tlsConfig rendering has an nindent bug that places fields as
siblings of tlsConfig rather than children, causing Prometheus Operator CRD validation
to fail. By not passing tlsConfig through upstream values and instead injecting it here
via JSON Patch, the bug is bypassed entirely.

Targets by kind only since there is exactly one ServiceMonitor in the garage release
and the name varies with the Flux release name. Applied when Istio is enabled, ambient
is not active, and mTLS mode is STRICT.
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
{{- end }}

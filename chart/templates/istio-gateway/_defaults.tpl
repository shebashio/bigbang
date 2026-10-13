{{- define "bigbang.defaults.istio-gateway" -}}
gateways:
  public:
    gateway:
      servers:
      - hosts:
        - '*.{{ .Values.domain }}'
        port:
          name: http
          number: 8080
          protocol: HTTP
        tls:
          httpsRedirect: true
      - hosts:
        - '*.{{ .Values.domain }}'
        port:
          name: https
          number: 8443
          protocol: HTTPS
        tls:
          credentialName: public-cert
          mode: SIMPLE
      {{- if and .Values.packages.keycloak.enabled (empty .Values.packages.keycloak.ingress.cert) (empty .Values.packages.keycloak.ingress.key) (or (empty .Values.packages.keycloak.ingress.gateway) (eq .Values.packages.keycloak.ingress.gateway "public")) }}
      - hosts:
        - 'keycloak.{{ .Values.domain }}'
        port:
          name: https-keycloak
          number: 8443
          protocol: HTTPS
        tls:
          credentialName: public-cert
          mode: OPTIONAL_MUTUAL
      {{- end }}
      
    upstream:
      imagePullPolicy: {{ .Values.imagePullPolicy }}

      {{- include "secretsImagePullSecretsWithName" . | nindent 6 }}

      labels:
        istio: ingressgateway

  passthrough:
    gateway:
      servers:
      - hosts:
        - '*.{{ .Values.domain }}'
        port:
          name: http
          number: 8080
          protocol: HTTP
        tls:
          httpsRedirect: true
      - hosts:
        - '*.{{ .Values.domain }}'
        port:
          name: https
          number: 8443
          protocol: HTTPS
        tls:
          mode: PASSTHROUGH

    upstream:
      imagePullPolicy: {{ .Values.imagePullPolicy }}

      {{- include "secretsImagePullSecretsWithName" . | nindent 6 }}

      labels:
        istio: ingressgateway
{{- end }}

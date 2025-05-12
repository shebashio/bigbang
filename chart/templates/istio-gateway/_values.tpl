{{- define "bigbang.defaults.istio-gateway" -}}
gateways:
  public:
    networkPolicies:
      enabled: {{ .Values.networkPolicies.enabled }}

    monitoring:
      enabled: {{ .Values.monitoring.enabled }}

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

    upstream:
      serviceAccount:
        create: true
        name: public-ingressgateway-ingressgateway-service-account

      imagePullPolicy: {{ .Values.imagePullPolicy }}

      imagePullSecrets:
        - name: private-registry

      labels:
        istio: ingressgateway

  passthrough:
    networkPolicies:
      enabled: {{ .Values.networkPolicies.enabled }}

    monitoring:
      enabled: {{ .Values.monitoring.enabled }}

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
      serviceAccount:
        create: true
        name: passthrough-ingressgateway-ingressgateway-service-account

      imagePullPolicy: {{ .Values.imagePullPolicy }}

      imagePullSecrets:
        - name: private-registry

      labels:
        istio: ingressgateway


{{- end -}}
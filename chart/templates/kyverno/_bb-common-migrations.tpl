{{- define "bigbang.kyverno.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}

{{- $legacyPorts := dig "networkPolicies" "externalRegistries" "ports" list .Values.kyverno.values }}
{{- $definitionDefaultPort := list (dict "port" 443 "protocol" "TCP") }}
{{- $definitionPorts := dig "networkPolicies" "egress" "definitions" "registry" "ports" $definitionDefaultPort .Values.kyverno.values }}
{{- $allPorts := concat $legacyPorts $definitionPorts }}
{{- $allPortsSanitized := list }}
{{- range $allPorts }}
  {{- $allPortsSanitized = append $allPortsSanitized (dict "port" (int .port) "protocol" (default "TCP" .protocol | upper)) }}
{{- end }}
{{- $uniquePorts := uniq $allPortsSanitized }}

networkPolicies:
  ingress:
    definitions:
      kubeAPI:
        from:
        {{- if or (eq .Values.networkPolicies.controlPlaneCidr "0.0.0.0/0") (eq .Values.networkPolicies.vpcCidr "0.0.0.0/0") }}
          - ipBlock:
              cidr: "0.0.0.0/0"
        {{- else }}
          - ipBlock:
              cidr: {{ .Values.networkPolicies.controlPlaneCidr }}
          - ipBlock:
              cidr: {{ .Values.networkPolicies.vpcCidr }}
        {{- end }}
  egress:
    definitions:
      kubeAPI:
        to:
        {{- if or (eq .Values.networkPolicies.controlPlaneCidr "0.0.0.0/0") (eq .Values.networkPolicies.vpcCidr "0.0.0.0/0") }}
          - ipBlock:
              cidr: "0.0.0.0/0"
              except:
              - 169.254.169.254/32
        {{- else }}
          - ipBlock:
              cidr: {{ .Values.networkPolicies.controlPlaneCidr }}
          - ipBlock:
              cidr: {{ .Values.networkPolicies.vpcCidr }}
        {{- end }}
      private-registry:
        to:
          - ipBlock:
              cidr: "15.205.173.153/32"
        ports:
        {{- toYaml $uniquePorts | nindent 10 }}
    from:
      kyverno-admission-controller:
        podSelector:
          matchLabels:
            app.kubernetes.io/component: admission-controller
        to:
          definition:
            private-registry: {{ dig "networkPolicies" "externalRegistries" "allowEgress" false .Values.kyverno.values }}
            kubeAPI: true
{{- end }}
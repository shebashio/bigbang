{{- define "bigbang.kyverno.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}

{{- $legacyPorts := dig "networkPolicies" "externalRegistries" "ports" list .Values.packages.kyverno.values }}
{{- $definitionDefaultPort := list (dict "port" 443 "protocol" "TCP") }}
{{- $definitionPorts := dig "networkPolicies" "egress" "definitions" "registry" "ports" $definitionDefaultPort .Values.packages.kyverno.values }}
{{- $allPorts := concat $legacyPorts $definitionPorts }}
{{- $allPortsSanitized := list }}
{{- range $allPorts }}
  {{- $allPortsSanitized = append $allPortsSanitized (dict "port" (int .port) "protocol" (default "TCP" .protocol | upper)) }}
{{- end }}
{{- $uniquePorts := uniq $allPortsSanitized }}

networkPolicies:
  egress:
    definitions:
      kubeAPI:
        to:
        - ipBlock:
            cidr: {{ .Values.networkPolicies.controlPlaneCidr }}
            {{- if eq .Values.networkPolicies.controlPlaneCidr "0.0.0.0/0" }}
            except:
              - "169.254.169.254/32"
            {{- end }}
        {{- if not (eq .Values.networkPolicies.controlPlaneCidr .Values.networkPolicies.vpcCidr) }}
        {{- if not (eq .Values.networkPolicies.vpcCidr "0.0.0.0/0") }}
        - ipBlock:
            cidr: {{ .Values.networkPolicies.vpcCidr }}
        {{- end }}
        {{- end }}
      # Keep in sync with private-registry in values.yaml: registry1 plus the
      # us-gov-west-1 S3 ranges it redirects blob downloads to.
      private-registry:
        to:
          - ipBlock:
              cidr: "15.205.173.153/32"
          - ipBlock:
              cidr: "108.175.56.0/22"
          - ipBlock:
              cidr: "108.175.48.0/22"
          - ipBlock:
              cidr: "136.18.0.0/23"
          - ipBlock:
              cidr: "3.2.99.0/24"
          - ipBlock:
              cidr: "1.178.30.0/24"
          - ipBlock:
              cidr: "15.200.176.128/28"
          - ipBlock:
              cidr: "15.200.28.240/28"
        ports:
        {{- toYaml $uniquePorts | nindent 10 }}
    from:
      kyverno-admission-controller:
        podSelector:
          matchLabels:
            app.kubernetes.io/component: admission-controller
        to:
          definition:
            private-registry: {{ or (dig "networkPolicies" "externalRegistries" "allowEgress" false .Values.packages.kyverno.values) (dig "policies" "require-image-signature" "enabled" false .Values.packages.kyvernoPolicies.values) }}
            kubeAPI: true
{{- end }}

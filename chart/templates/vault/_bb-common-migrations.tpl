{{- define "bigbang.vault.bb-common-migrations" }}
{{/* TODO: Remove this migration template for bb 4.0 */}}

networkPolicies:
  egress:
    definitions:
      kubeAPI:
        to:
          {{- if or (eq .Values.networkPolicies.controlPlaneCidr "0.0.0.0/0") (eq .Values.networkPolicies.vpcCidr "0.0.0.0/0")}}
          - ipBlock:
              cidr: "0.0.0.0/0"
              # ONLY Block requests to cloud metadata IP
              except:
              - 169.254.169.254/32
          {{- else }}
          - ipBlock:
              cidr: {{ .Values.networkPolicies.controlPlaneCidr }}
          - ipBlock:
              cidr: {{ .Values.networkPolicies.vpcCidr }}
          {{- end }}
      kms:
        to:
          - ipBlock:
              cidr: {{ .Values.networkPolicies.vpcCidr }}
              {{- if eq .Values.networkPolicies.vpcCidr "0.0.0.0/0" }}
              except:
              - 169.254.169.254/32
              {{- end }}
        ports:
          - port: 443
            protocol: TCP
    from:
      vault:
        to:
          definitions:
            kubeAPI: true
            kms: true
      vault-agent-injector:
        to:
          definition:
            kubeAPI: true
      vault-autoinit:
        podSelector:
          matchLabels:
            batch.kubernetes.io/job-name: vault-vault-job-init
        to:
          definition:
            kubeAPI: true
{{- end }}
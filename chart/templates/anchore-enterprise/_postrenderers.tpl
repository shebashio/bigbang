{{- define "anchoreEnterprise.licensePostRenderer" }}
    - kustomize:
        patches:
          - target:
              kind: Secret
              name: anchore-enterprise-license
              namespace: anchore
            patch: |-
              - op: replace
                path: /stringData/license.yaml
                value: |
                  # Anchore Enterprise License - installed via Helm
                  #
{{ toYaml .Values.enterpriseLicenseYaml | indent 18 }}
{{- end }}
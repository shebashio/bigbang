{{- define "nxrm-ha.prometheusPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /metadata/labels/app
            value: nexus-repository-manager-nxrm-ha
          - op: replace
            path: /spec/ports/0/name
            value: http-nexus-ui
        target:
          kind: Service
          name: nexus-repository-manager
      - patch: |
          - op: replace
            path: /spec/ports/0/name
            value: http-nexus-ui
        target:
          kind: Service
          name: nexus-repository-manager-hl
{{- end }}
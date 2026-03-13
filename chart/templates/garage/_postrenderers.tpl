{{- define "garage.postRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /spec/template/spec/initContainers/0/name
            value: garage-init
          - op: replace
            path: /spec/template/spec/containers/0/name
            value: garage
        target:
          kind: StatefulSet
          name: garage
{{- end }}

{{- define "alloy.bigBangPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/template/metadata/labels/app.kubernetes.io~1version
            value: v1.5.1
        target:
          kind: StatefulSet
          name: monitoring-alloy
{{- end }}
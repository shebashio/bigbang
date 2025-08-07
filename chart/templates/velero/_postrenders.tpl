{{- define "velero.upgradeCRDsPostrenderers" }}
- kustomize:
    patches:
        - patch: |
            - op: replace
            path: /spec/template/metadata/initContainers/0/args/1
            value: "cp /bin/sh /tmp && cp /usr/local/bin/kubectl /tmp"
        target:
        kind: Job
        name: upgrade-crds
{{- end }}

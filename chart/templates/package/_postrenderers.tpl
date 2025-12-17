{{- /*
  Package-specific postRenderers for bb_maintained packages.
  Each package gets a named template that receives the package name as context.

  Usage in helmrelease.yaml:
    {{- include "bb.postrenderers" (dict "repoName" $repoName "pkg" $pkg) -}}
*/ -}}

{{- /* Main lookup helper - returns postRenderers YAML for a given repo */ -}}
{{- define "bb.postrenderers" -}}
{{- $repoName := .repoName -}}
{{- $pkg := .pkg -}}
{{- if eq $repoName "nxrm-ha" -}}
{{- include "bb.postrenderers.nxrm-ha" $pkg -}}
{{- end -}}
{{- /* Add additional packages here as needed:
{{- else if eq $repoName "another-pkg" -}}
{{- include "bb.postrenderers.another-pkg" $pkg -}}
*/ -}}
{{- end -}}

{{- /* nxrm-ha postRenderers */ -}}
{{- define "bb.postrenderers.nxrm-ha" -}}
- kustomize:
    patches:
      # Add app label for Prometheus ServiceMonitor compatibility
      - patch: |
          - op: add
            path: /metadata/labels/app
            value: {{ . }}
          - op: replace
            path: /spec/ports/0/name
            value: http-nexus-ui
        target:
          kind: Service
          name: {{ . }}
      # Patch headless service port name
      - patch: |
          - op: replace
            path: /spec/ports/0/name
            value: http-nexus-ui
        target:
          kind: Service
          name: {{ . }}-hl
{{- end -}}

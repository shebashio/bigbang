{{- define "renovate.fixCronjobPostRender" }}
- kustomize:
    patches:
        - patch: | 
          - op: add
            path: /spec/jobTemplate/spec/template/spec/containers[0]
            value:
              name: {{ .Chart.Name }}
              {{ if .Values.istio.enabled }}
              command: ["/bin/sh"]
              args:
                - -c
                - >-
                  docker-entrypoint.sh;
                  x=$(echo $?);
                  curl -fsI -X POST http://localhost:15020/quitquitquit;
                  exit $x;
              {{ end }}
    target:
      kind: Cronjob
      name: renovate
{{- end }}
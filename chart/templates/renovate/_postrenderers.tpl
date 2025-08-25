{{- define "renovate.fixCronjobPostRender" }}
- kustomize:
    patches:
        - patch: | 
          - op: add
            path: /spec/jobTemplate/spec/template/spec/containers[0]
            value:
              name: renovate
              command: ["/bin/sh"]
              args:
                - -c
                - >-
                  docker-entrypoint.sh;
                  x=$(echo $?);
                  curl -fsI -X POST http://localhost:15020/quitquitquit;
                  exit $x;

    target:
      kind: Cronjob
      name: renovate
{{- end }} 
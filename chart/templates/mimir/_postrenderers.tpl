{{- define "mimir.istioPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /spec/ports/1/appProtocol
            value: tcp
        target:
          kind: Service
          name: .*-headless$
      - patch: |
          - op: add
            path: /spec/ports/1/appProtocol
            value: grpc
        target:
          kind: Service
          name: ^.+-(?:alertmanager|compactor|distributor|ingester(-zone.*)?|overrides-exporter|querier|query-frontend|store-gateway(-zone.*))$
      - patch: |
          - op: add
            path: /spec/template/metadata/labels/app.kubernetes.io~1part-of
            value: memberlist
        target:
          kind: Deployment
          name: ^.+-query-frontend$
      - patch: |
          - op: add
            path: /spec/template/spec/containers/0/ports/-
            value:
              containerPort: 7946
              name: memberlist
              protocol: TCP
        target:
          kind: Deployment
          name: ^.+-query-frontend$
      # Set failurePolicy: Ignore on the rollout-operator admission webhooks so that
      # StatefulSet operations are not blocked when the rollout-operator pod is
      # temporarily unavailable (e.g. during upgrades, rollbacks, or initial install
      # before the minio-tenant StatefulSet can be created). With failurePolicy: Fail
      # (upstream default), any StatefulSet mutation is rejected until rollout-operator
      # is ready, which can cause rollbacks to deadlock with a 502 Bad Gateway error.
      # In a GitOps environment, uncoordinated downscales are not a practical risk as
      # all StatefulSet mutations flow through Flux. Remove these patches when upstream
      # mimir-distributed resolves the ordering issue.
      - patch: |
          - op: replace
            path: /webhooks/0/failurePolicy
            value: Ignore
        target:
          group: admissionregistration.k8s.io
          kind: MutatingWebhookConfiguration
          name: ^prepare-downscale-.*$
      - patch: |
          - op: replace
            path: /webhooks/0/failurePolicy
            value: Ignore
        target:
          group: admissionregistration.k8s.io
          kind: ValidatingWebhookConfiguration
          name: ^no-downscale-.*$
{{- end }}
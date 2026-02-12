{{- define "anchore-enterprise.postRenderers" }}
- kustomize:
    patches:

      # Catalog
      - patch: |
          apiVersion: v1
          kind: Service
          metadata:
            name: anchore-enterprise-anchore-enterprise-catalog
          spec:
            ports:
              - name: catalog
                appProtocol: http
        target:
          kind: Service
          name: anchore-enterprise-anchore-enterprise-catalog

      # API
      - patch: |
          apiVersion: v1
          kind: Service
          metadata:
            name: anchore-enterprise-anchore-enterprise-api
          spec:
            ports:
              - name: api
                appProtocol: http
        target:
          kind: Service
          name: anchore-enterprise-anchore-enterprise-api

      # Policy Engine
      - patch: |
          apiVersion: v1
          kind: Service
          metadata:
            name: anchore-enterprise-anchore-enterprise-policy
          spec:
            ports:
              - name: policyEngine
                appProtocol: http
        target:
          kind: Service
          name: anchore-enterprise-anchore-enterprise-policy

      # SimpleQueue
      - patch: |
          apiVersion: v1
          kind: Service
          metadata:
            name: anchore-enterprise-anchore-enterprise-simplequeue
          spec:
            ports:
              - name: simpleQueue
                appProtocol: http
        target:
          kind: Service
          name: anchore-enterprise-anchore-enterprise-simplequeue

      # Analyzer
      - patch: |
          apiVersion: v1
          kind: Service
          metadata:
            name: anchore-enterprise-anchore-enterprise-analyzer
          spec:
            ports:
              - name: analyzer
                appProtocol: http
        target:
          kind: Service
          name: anchore-enterprise-anchore-enterprise-analyzer

      # Reports
      - patch: |
          apiVersion: v1
          kind: Service
          metadata:
            name: anchore-enterprise-anchore-enterprise-reports
          spec:
            ports:
              - name: reports
                appProtocol: http
        target:
          kind: Service
          name: anchore-enterprise-anchore-enterprise-reports

      # Notifications
      - patch: |
          apiVersion: v1
          kind: Service
          metadata:
            name: anchore-enterprise-anchore-enterprise-notifications
          spec:
            ports:
              - name: notifications
                appProtocol: http
        target:
          kind: Service
          name: anchore-enterprise-anchore-enterprise-notifications

{{- end }}

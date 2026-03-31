{{- define "bigbang.policyexceptions.argocd" }}

argocd-add-default-capability-drop:
    metadata:
        namespace: kyverno
        labels:
        app: argocd
        annotations:
            policies.kyverno.io/description: "# application-controller pods interact with secrets, configmaps, events, and Argo CRDs
          # More details in argocd/chart/templates/argocd-application-controller/role.yaml"
    spec:
        exceptions:
        - policyName: add-default-capability-drop
        ruleNames:
        - add-default-capability-drop
        match:
        any:
        - resources:
            names:
            - guestbook-ui-*
            namespaces:
            - argocd
{{- end }}
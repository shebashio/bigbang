{{- define "bigbang.policyexceptions.argocd" }}

argocd-add-default-capability-drop:
    metadata:
        namespace: kyverno
        labels:
        app: argocd
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
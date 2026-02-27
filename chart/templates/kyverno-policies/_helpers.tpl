{{- /*

  PolicyException Helpers

  Helm template helpers for generating Kyverno PolicyException entries
  in the additionalPolicyExceptions map. These support the migration from
  inline ClusterPolicy exclude blocks to PolicyException CRD objects.


*/ -}}


{{- /*

  bigbang.policyException

  Generates a single additionalPolicyExceptions map entry.

  Required keys:
    .name        — map key for the exception (e.g. "neuvector-disallow-host-namespaces")
    .enabled     — boolean or template expression controlling whether the exception renders
    .policy      — the ClusterPolicy name to exempt from (e.g. "disallow-host-namespaces")
    .namespaces  — list of target namespaces to match (e.g. (list "neuvector"))

  Optional keys:
    .names       — list of resource name patterns (e.g. (list "neuvector-enforcer-pod*"))
                   omit for namespace-only (static) exceptions
    .kinds       — list of resource kinds (e.g. (list "Pod" "Deployment"))
                   omit to match all kinds
    .ruleNames   — list of rule names to exempt (defaults to the policy name, which
                   matches the kyverno-policies subchart convention)

  Usage:

    {{- include "bigbang.policyException" (dict
      "name"       "neuvector-disallow-host-namespaces"
      "enabled"    .Values.neuvector.enabled
      "policy"     "disallow-host-namespaces"
      "namespaces" (list "neuvector")
      "names"      (list "neuvector-enforcer-pod*")
    ) | nindent 4 }}

*/ -}}
{{- define "bigbang.policyException" -}}
{{ .name }}:
  enabled: {{ .enabled }}
  kind: PolicyException
  namespace: "kyverno"
  metadata:
    labels:
      app: {{ splitList "-" .name | first | quote }}
  spec:
    exceptions:
    - policyName: {{ .policy }}
      ruleNames:
      {{- if .ruleNames }}
      {{- range .ruleNames }}
      - {{ . | quote }}
      {{- end }}
      {{- else }}
      - {{ .policy | quote }}
      {{- end }}
    match:
      any:
      - resources:
          {{- with .kinds }}
          kinds:
          {{- range . }}
          - {{ . }}
          {{- end }}
          {{- end }}
          namespaces:
          {{- range .namespaces }}
          - {{ . }}
          {{- end }}
          {{- with .names }}
          names:
          {{- range . }}
          - {{ . | quote }}
          {{- end }}
          {{- end }}
{{- end -}}


{{- /*

  bigbang.policyExceptionBatch

  Generates multiple additionalPolicyExceptions map entries that share
  the same match criteria (namespaces, names, kinds) across several policies.
  Map keys are auto-generated as "<addon>-<policy>".

  Required keys:
    .addon       — addon name, used as the key prefix (e.g. "fluentbit")
    .enabled     — boolean or template expression
    .namespaces  — list of target namespaces
    .policies    — list of ClusterPolicy names to exempt from

  Optional keys:
    .names       — list of resource name patterns (omit for namespace-only)
    .kinds       — list of resource kinds (omit to match all kinds)

  Usage:

    {{- include "bigbang.policyExceptionBatch" (dict
      "addon"      "fluentbit"
      "enabled"    .Values.fluentbit.enabled
      "namespaces" (list "fluentbit")
      "names"      (list "fluentbit-fluent-bit*")
      "policies"   (list
        "add-default-securitycontext"
        "disallow-privileged-containers"
        "disallow-tolerations"
        "require-non-root-group"
        "require-non-root-user"
        "restrict-host-path-mount"
        "restrict-selinux-type"
        "restrict-volume-types"
      )
    ) | nindent 4 }}

*/ -}}
{{- define "bigbang.policyExceptionBatch" -}}
{{- $ctx := . -}}
{{- range $policy := .policies }}
{{- $entry := dict
  "name"       (printf "%s-%s" $ctx.addon $policy)
  "enabled"    $ctx.enabled
  "policy"     $policy
  "namespaces" $ctx.namespaces
-}}
{{- if $ctx.names }}{{ $_ := set $entry "names" $ctx.names }}{{ end -}}
{{- if $ctx.kinds }}{{ $_ := set $entry "kinds" $ctx.kinds }}{{ end -}}
{{ include "bigbang.policyException" $entry }}
{{ end -}}
{{- end -}}

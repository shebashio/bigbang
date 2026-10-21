{{- define "values-bigbang" -}}
{{- $values := .Values -}}
{{ toYaml (pick $values "domain" "openshift") }}
{{- with $values.istio }}
istio:
  {{- if hasKey . "enabled" }}
  enabled: {{ .enabled }}
  {{- end }}
  ambient:
    enabled: {{ include "ambientEnabled" (dict "Values" $values) }}
{{- end }}
{{- with $values.networkPolicies }}
networkPolicies:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- $catalog := (.Files.Get "package-metadata.yaml" | fromYaml).packages -}}
{{- range $name, $metadata := $catalog -}}
  {{- $package := get $values.packages $name | default dict -}}
  {{- if and (eq $metadata.category "core") (hasKey $package "enabled") }}
{{ $name }}:
  enabled: {{ $package.enabled }}
  {{- end -}}
{{- end }}
addons:
{{- range $name, $metadata := $catalog -}}
  {{- $package := get $values.packages $name | default dict -}}
  {{- if and (eq $metadata.category "addon") (hasKey $package "enabled") }}
  {{ $name }}:
    enabled: {{ $package.enabled }}
    {{- if and (eq $name "authservice") (or (dig "values" "selector" "key" false $package) (dig "values" "selector" "value" false $package)) }}
    values:
      selector:
      {{- with (dig "values" "selector" "key" false $package) }}
        key: {{ . }}
      {{- end }}
      {{- with (dig "values" "selector" "value" false $package) }}
        value: {{ . }}
      {{- end }}
    {{- end }}
  {{- end -}}
{{- end -}}
{{- end }}

{{/* Separate integrated packages from user-supplied packages and reserve their names. */}}
{{- define "bigbang.normalizePackageAliases" -}}
{{- $packages := .Values.packages | default dict -}}
{{- $metadata := .Files.Get "package-metadata.yaml" | fromYaml -}}
{{- $catalog := get $metadata "packages" | default dict -}}
{{- if not $catalog -}}
  {{- fail "chart/package-metadata.yaml must define built-in packages" -}}
{{- end -}}
{{- /* Reject old keys while the 4.0 schema migration is in progress. */ -}}
{{- $addons := get .Values "addons" | default dict -}}
{{- range $name, $package := $catalog -}}
  {{- if and (eq $package.category "core") (hasKey $.Values $name) -}}
    {{- fail (printf "%s is no longer supported; move its values to packages.%s" $name $name) -}}
  {{- end -}}
  {{- if and (eq $package.category "addon") (hasKey $addons $name) -}}
    {{- fail (printf "addons.%s is no longer supported; move its values to packages.%s" $name $name) -}}
  {{- end -}}
{{- end -}}
{{- if hasKey $addons "mattermostoperator" -}}
  {{- fail "addons.mattermostoperator is no longer supported; move its values to packages.mattermostOperator" -}}
{{- end -}}
{{- $customPackages := dict -}}
{{- $reservedNames := dict -}}
{{- range $name, $package := $catalog -}}
  {{- $identities := uniq (list (lower $name) (include "resourceName" $name) (lower $package.templateDirectory)) -}}
  {{- range $identity := $identities -}}
    {{- if and (hasKey $reservedNames $identity) (ne (get $reservedNames $identity) $name) -}}
      {{- fail (printf "built-in packages %s and %s share reserved identity %s" (get $reservedNames $identity) $name $identity) -}}
    {{- end -}}
    {{- $_ := set $reservedNames $identity $name -}}
  {{- end -}}
{{- end -}}
{{- $customResourceNames := dict -}}
{{- range $name := keys $packages | sortAlpha -}}
  {{- if not (hasKey $catalog $name) -}}
    {{- $identities := uniq (list (lower $name) (include "resourceName" $name)) -}}
    {{- range $identity := $identities -}}
      {{- if hasKey $reservedNames $identity -}}
        {{- $owner := get $reservedNames $identity -}}
        {{- fail (printf "packages.%s conflicts with built-in package packages.%s; use the canonical name packages.%s" $name $owner $owner) -}}
      {{- end -}}
    {{- end -}}
    {{- $resourceName := include "resourceName" $name -}}
    {{- if hasKey $customResourceNames $resourceName -}}
      {{- fail (printf "packages.%s and packages.%s normalize to the same package identity" (get $customResourceNames $resourceName) $name) -}}
    {{- end -}}
    {{- $_ := set $customResourceNames $resourceName $name -}}
    {{- $_ := set $customPackages $name (get $packages $name) -}}
  {{- end -}}
{{- end -}}
{{- $_ := set .Values "_customPackages" $customPackages -}}
{{- end -}}

{{- define "imagePullSecret" }}
  {{- if .Values.registryCredentials -}}
    {{- $credType := typeOf .Values.registryCredentials -}}
          {{- /* If we have a list, embed that here directly. This allows for complex configuration from configmap, downward API, etc. */ -}}
    {{- if eq $credType "[]interface {}" -}}
    {{- include "multipleCreds" . | b64enc }}
    {{- else if eq $credType "map[string]interface {}" }}
      {{- /* If we have a map, treat those as key-value pairs. */ -}}
      {{- if and .Values.registryCredentials.username .Values.registryCredentials.password }}
      {{- with .Values.registryCredentials }}
      {{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" (default "registry1.dso.mil" .registry) .username .password (default "" .email) (printf "%s:%s" .username .password | b64enc) | b64enc }}
      {{- end }}
      {{- end }}
    {{- end -}}
  {{- end }}
{{- end }}

{{/*
Render a Namespace for an integrated package.
The caller resolves package-specific enablement and passes the package values used
to determine sidecar injection. Special namespaces with user-provided metadata or
multiple resources remain in their package templates.

Args (dict):
  - root: root chart context ($ or .)
  - name: Namespace metadata.name
  - appName: app.kubernetes.io/name label value
  - component: app.kubernetes.io/component label value (optional)
  - package: package values containing istio.injection (string; defaults to "enabled")
  - extraLabels: additional labels to render (optional)
  - annotations: additional annotations to render (optional)
  - meshMode: "auto" (default) or "none"
*/}}
{{- define "bigbang.namespace" -}}
{{- $name := required "bigbang.namespace: name is required" .name -}}
{{- $appName := required "bigbang.namespace: appName is required" .appName -}}
{{- $meshMode := "auto" -}}
{{- if hasKey . "meshMode" -}}
{{- $candidate := get . "meshMode" -}}
{{- if not (kindIs "string" $candidate) -}}
{{- fail (printf "bigbang.namespace: meshMode for namespace %q must be a string, got %s" $name (kindOf $candidate)) -}}
{{- end -}}
{{- $meshMode = $candidate -}}
{{- end -}}
{{- $validMeshModes := list "auto" "none" -}}
{{- if not (has $meshMode $validMeshModes) -}}
{{- fail (printf "bigbang.namespace: unsupported meshMode %q for namespace %q; expected one of: %s" $meshMode $name (join ", " $validMeshModes)) -}}
{{- end -}}
{{- $istioEnabled := eq (include "istioEnabled" .root) "true" -}}
{{- $labels := include "commonLabels" .root | fromYaml -}}
{{- with .extraLabels -}}
{{- $labels = mustMergeOverwrite $labels . -}}
{{- end -}}
{{- $labels = set $labels "app.kubernetes.io/name" $appName -}}
{{- with .component -}}
{{- $labels = set $labels "app.kubernetes.io/component" . -}}
{{- end -}}
{{- if eq $meshMode "none" -}}
{{- $labels = set $labels "istio-injection" "disabled" -}}
{{- $labels = set $labels "istio.io/dataplane-mode" "none" -}}
{{- else if eq (include "ambientEnabled" .root) "true" -}}
{{- $labels = set $labels "istio.io/dataplane-mode" "ambient" -}}
{{- else -}}
{{- $labels = set $labels "istio-injection" (ternary "enabled" "disabled" (and $istioEnabled (eq (dig "istio" "injection" "enabled" (default dict .package)) "enabled"))) -}}
{{- end -}}
apiVersion: v1
kind: Namespace
metadata:
  name: {{ $name }}
  {{- with .annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- toYaml $labels | nindent 4 }}
{{- end }}

{{/*
Render the standard private registry Secret used by integrated packages.
The caller is responsible for package-specific enablement and ownership checks.

Args (dict):
  - root: root chart context ($ or .)
  - namespace: namespace that receives the Secret
  - appName: app.kubernetes.io/name label value (optional)
  - component: app.kubernetes.io/component label value (optional)
  - commonLabels: include common labels when no appName/component is supplied (optional)
*/}}
{{- define "bigbang.imagePullSecret" -}}
{{- if (include "imagePullSecret" .root) }}
apiVersion: v1
kind: Secret
metadata:
  name: private-registry
  namespace: {{ .namespace }}
  {{- if or .appName .component .commonLabels }}
  labels:
    {{- with .appName }}
    app.kubernetes.io/name: {{ . }}
    {{- end }}
    {{- with .component }}
    app.kubernetes.io/component: {{ . | quote }}
    {{- end }}
    {{- include "commonLabels" .root | nindent 4 }}
  {{- end }}
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: {{ include "imagePullSecret" .root }}
{{- end }}
{{- end }}

{{- define "multipleCreds" -}}
{
  "auths": {
    {{- range $i, $m := .Values.registryCredentials }}
    {{- /* Only create entry if resulting entry is valid */}}
    {{- if and $m.registry $m.username $m.password }}
    {{- if $i }},{{ end }}
    "{{ $m.registry }}": {
      "username": "{{ $m.username }}",
      "password": "{{ $m.password }}",
      "email": "{{ $m.email | default "" }}",
      "auth": "{{ printf "%s:%s" $m.username $m.password | b64enc }}"
    }
    {{- end }}
    {{- end }}
  }
}
{{- end }}

{{- define "secretsImagePullSecretsSingle" -}}
{{- if ( include "imagePullSecret" . ) }}
imagePullSecrets: private-registry
{{- else }}
imagePullSecrets: []
{{- end }}
{{- end }}

{{- define "secretsImagePullSecretWithName" -}}
{{- if ( include "imagePullSecret" . ) }}
imagePullSecret: 
  name: private-registry
{{- else }}
imagePullSecret:
  name: ""
{{- end }}
{{- end }}

{{- define "secretsImagePullSecretsWithName" -}}
{{- if ( include "imagePullSecret" . ) }}
imagePullSecrets: 
  - name: private-registry
{{- else }}
imagePullSecrets: []
{{- end }}
{{- end }}

{{- define "secretsImagePullSecrets" -}}
{{- if ( include "imagePullSecret" . ) }}
imagePullSecrets: 
  - private-registry
{{- else }}
imagePullSecrets: []
{{- end }}
{{- end }}

{{- define "secretsPullSecretsWithName" -}}
{{- if ( include "imagePullSecret" . ) }}
pullSecrets: 
  - name: private-registry
{{- else }}
pullSecrets: []
{{- end }}
{{- end }}

{{- define "secretsPullSecrets" -}}
{{- if ( include "imagePullSecret" . ) }}
pullSecrets: 
  - private-registry
{{- else }}
pullSecrets: []
{{- end }}
{{- end }}

{{- define "secretsPullSecret" -}}
{{- if ( include "imagePullSecret" . ) }}
pullSecret: private-registry
{{- else }}
pullSecret: ""
{{- end }}
{{- end }}

{{- define "secretsPullSecretsSingle" -}}
{{- if ( include "imagePullSecret" . ) }}
pullSecrets: private-registry
{{- else }}
pullSecrets: ""
{{- end }}
{{- end }}

{{/*
Build the appropriate spec.ref.{} given git branch, commit values
*/}}
{{- define "validRef" -}}
{{- if .commit -}}
{{- if not .branch -}}
{{- fail "A valid branch is required when a commit is specified!" -}}
{{- end -}}
branch: {{ .branch | quote }}
commit: {{ .commit }}
{{- else if .semver -}}
semver: {{ .semver | quote }}
{{- else if .tag -}}
tag: {{ .tag }}
{{- else -}}
branch: {{ .branch | quote }}
{{- end -}}
{{- end -}}

{{/*
Build the appropriate git credentials secret for BB wide git repositories
*/}}
{{- define "gitCredsGlobal" -}}
{{- if .Values.git.existingSecret -}}
secretRef:
  name: {{ .Values.git.existingSecret }}
{{- else if coalesce .Values.git.credentials.username .Values.git.credentials.password .Values.git.credentials.caFile .Values.git.credentials.privateKey .Values.git.credentials.publicKey .Values.git.credentials.knownHosts "" -}}
{{- /* Input validation happens in git-credentials.yaml template */ -}}
secretRef:
  name: {{ $.Release.Name }}-git-credentials
{{- end -}}
{{- end -}}

{{/*
Build the appropriate git credentials secret for individual package and BB wide private git repositories
*/}}
{{- define "gitCredsExtended" -}}
{{- if .packageGitScope.existingSecret -}}
secretRef:
  name: {{ .packageGitScope.existingSecret }}
{{- else if and (.packageGitScope.credentials) (coalesce .packageGitScope.credentials.username .packageGitScope.credentials.password .packageGitScope.credentials.caFile .packageGitScope.credentials.privateKey .packageGitScope.credentials.publicKey .packageGitScope.credentials.knownHosts "") -}}
{{- /* Input validation happens in git-credentials.yaml template */ -}}
secretRef:
  name: {{ .releaseName }}-{{ include "resourceName" .name }}-git-credentials
{{- else -}}
{{/* If no credentials are specified, use the global credentials in the rootScope */}}
{{- include "gitCredsGlobal" .rootScope }}
{{- end -}}
{{- end -}}

{{/*
Pointer to the appropriate git credentials template
*/}}
{{- define "gitCreds" -}}
{{- include "gitCredsGlobal" . }}
{{- end -}}

{{/*
Merge legacy istio.hardened keys into new structure
Args:
  - values: The package values to clean (e.g. .Values.packages.kiali.values)

This helper merges:
  - istio.hardened.customServiceEntries -> istio.serviceEntries.custom
  - istio.hardened.customAuthorizationPolicies -> istio.authorizationPolicies.custom

Returns cleaned values with hardened key removed.
*/}}
{{- define "mergeLegacyIstioHardenedKeys" -}}
{{- $values := .values -}}
{{- if $values.istio -}}
{{- $cleanedIstio := deepCopy $values.istio -}}

{{- /* Merge hardened.customServiceEntries into serviceEntries.custom */ -}}
{{- $hardenedServiceEntries := dig "hardened" "customServiceEntries" list $values.istio }}
{{- $currentServiceEntries := dig "serviceEntries" "custom" list $values.istio }}
{{- $mergedServiceEntries := concat $hardenedServiceEntries $currentServiceEntries }}
{{- if $mergedServiceEntries }}
{{- $_ := set $cleanedIstio "serviceEntries" (dict "custom" $mergedServiceEntries) }}
{{- end }}

{{- /* Merge hardened.customAuthorizationPolicies into authorizationPolicies.custom */ -}}
{{- $hardenedAuthzPolicies := dig "hardened" "customAuthorizationPolicies" list $values.istio }}
{{- $currentAuthzPolicies := dig "authorizationPolicies" "custom" list $values.istio }}
{{- $mergedAuthzPolicies := concat $hardenedAuthzPolicies $currentAuthzPolicies }}
{{- if $mergedAuthzPolicies }}
{{- $_ := set $cleanedIstio "authorizationPolicies" (dict "custom" $mergedAuthzPolicies) }}
{{- end }}

{{- /* Drop only the two sub-fields that were migrated above; anything else under
       hardened (notably hardened.enabled, still read by commonPackageDefaults and
       authorizationPoliciesEnabled) must survive. */ -}}
{{- $hardenedRemaining := omit (dig "hardened" dict $values.istio) "customServiceEntries" "customAuthorizationPolicies" -}}
{{- if $hardenedRemaining -}}
{{- $_ := set $cleanedIstio "hardened" $hardenedRemaining -}}
{{- else -}}
{{- $cleanedIstio = unset $cleanedIstio "hardened" -}}
{{- end -}}

{{- $values = set $values "istio" $cleanedIstio -}}
{{- end -}}
{{- toYaml $values -}}
{{- end -}}

{{/*
Shared GitRepository resource template.
Args (dict):
  - name: resource name (kebab-case, e.g. "kyverno-policies")
  - gitCredsName: name for gitCredsExtended (e.g. "kyvernoPolicies")
  - git: the .git values object (repo, branch, tag, semver, commit, credentials)
  - component: app.kubernetes.io/component label value (optional)
  - root: root context ($ or .)
  - extraIgnore: additional gitignore lines appended after standard gitIgnore (optional)
*/}}
{{- define "bigbang.gitRepository" -}}
{{- $gitCredsDict := dict
  "name" .gitCredsName
  "packageGitScope" .git
  "rootScope" .root
  "releaseName" .root.Release.Name
}}
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: {{ .name }}
  namespace: {{ .root.Release.Namespace }}
  labels:
    app.kubernetes.io/name: {{ .name }}
    {{- if .component }}
    app.kubernetes.io/component: {{ .component | quote }}
    {{- end }}
    {{- include "commonLabels" .root | nindent 4 }}
spec:
  interval: {{ .root.Values.flux.interval }}
  url: {{ .git.repo }}
  ref:
    {{- include "validRef" .git | nindent 4 }}
  {{ include "gitIgnore" .root }}
  {{- if .extraIgnore }}
    {{ .extraIgnore }}
  {{- end }}
  {{- include "gitCredsExtended" $gitCredsDict | nindent 2 }}
{{- end -}}

{{/*
Build common set of file extensions to include/exclude
*/}}
{{- define "gitIgnore" -}}
  ignore: |
    # exclude file extensions
    /**/*.md
    /**/*.txt
    /**/*.sh
    !/chart/tests/scripts/*.sh
    !/chart/wait/*.sh
{{- end -}}

{{/*
Common labels for all objects
*/}}
{{- define "commonLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ default .Chart.Version .Chart.AppVersion | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: "bigbang"
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- /*
values-secret builds the <package>-values Secret consumed by a package's HelmRelease.
Args (dict):
  root:                 root context ($)
  package:               the package's resolved values (e.g. .Values.packages.kiali)
  name:                  the rendered resource name (e.g. "kiali")
  defaults:              rendered YAML text of the package's own bigbang.defaults.<name> template
  injectCommonDefaults:  optional, default true. When true, the istio/networkPolicies bb-common
                         scaffolding (see bigbang.commonPackageDefaults) is deep-merged in
                         underneath `defaults`, so packages don't need to declare it themselves.
                         Set to false for packages with no running workload that shouldn't get
                         istio/networkPolicies values at all (e.g. CRD-only packages like
                         istio-crds, prometheus-operator-crds).
  bbCommonSubchart:      optional, default false. bb-common is currently consumed as a library
                         chart, which reads its istio/networkPolicies/routes values from the top
                         level of the values passed to the HelmRelease. Once a package's bb-common
                         dependency moves to being a regular subchart, those same values need to
                         be nested under a `bb-common` key instead (Helm's normal subchart value
                         scoping). Set to true for a package that has made that switch. Note routes
                         is picked only when present, since not every package declares one. Once
                         every package has migrated, this condition should be made unconditional
                         and the parameter removed from every values-secret call site.
*/ -}}
{{- define "values-secret" -}}
{{- $packageValues := default dict .package.values -}}
{{- $explicitDefaults := default (dict) (fromYaml .defaults) -}}
{{- /* A package's own defaults may declare istio/networkPolicies/routes either flat or nested 
       under bb-common when used as a sub-chart. Normalize to flat here so everything below 
       only has to handle one shape, regardless of usage or use of the bbCommonSubchart flag. */ -}}
{{- if hasKey $explicitDefaults "bb-common" }}
{{- $explicitDefaults = mustMergeOverwrite (omit $explicitDefaults "bb-common") (deepCopy (index $explicitDefaults "bb-common")) -}}
{{- end }}
{{- $defaults := $explicitDefaults | toYaml -}}
{{- if dig "injectCommonDefaults" true . }}
{{- $sharedDefaults := include "bigbang.commonPackageDefaults" (list $packageValues .package .root) | fromYaml -}}
{{- $defaults = mustMergeOverwrite (deepCopy $sharedDefaults) (deepCopy $explicitDefaults) | toYaml -}}
{{- end }}
{{- $commonValues := mustMergeOverwrite (deepCopy ($defaults | fromYaml)) (deepCopy $packageValues) }}
{{- $commonBlock := pick $commonValues "istio" "networkPolicies" }}
{{- $remainingDefaults := $defaults }}
{{- /* TODO(bb-common-subchart-migration): once every package's bb-common dependency is a
       regular subchart, drop this condition (always nest under bb-common, always omit
       injection, always strip istio/networkPolicies from defaults) and remove the
       "bbCommonSubchart" arg from every values-secret call site. */ -}}
{{- if dig "bbCommonSubchart" false . }}
{{- /* routes is a top-level bb-common key too, but not every package declares one. */ -}}
{{- $commonBlock = merge $commonBlock (pick $commonValues "routes") }}
{{- if hasKey $commonBlock "istio" }}
{{- /* injection and hardened are Big Bang-only controls, not bb-common subchart values.
       commonPackageDefaults has already derived hardened.enabled into sidecar.enabled. */ -}}
{{- $commonBlock = set $commonBlock "istio" (omit $commonBlock.istio "injection" "hardened") }}
{{- end }}
{{- $commonBlock = dict "bb-common" $commonBlock }}
{{- /* istio/networkPolicies/routes are fully captured above (common already reflects
       overlay+defaults merged), so strip them out of defaults to avoid re-flattening them
       there. Left untouched in library-chart mode, since defaults is relied on there as the
       full effective picture (e.g. by unittests asserting against stringData.defaults). */ -}}
{{- $remainingDefaults = omit ($defaults | fromYaml) "istio" "networkPolicies" "routes" | toYaml }}
{{- end }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .root.Release.Name }}-{{ .name }}-values
  namespace: {{ .root.Release.Namespace }}
type: generic
stringData:
  common: |
    {{- toYaml $commonBlock | nindent 4 }}
  defaults: {{- toYaml $remainingDefaults | nindent 4 }}
  overlays: |
    {{- toYaml .package.values | nindent 4 }}
{{- end -}}

{{- define "enabledGateways" -}}
  {{- $userGateways := deepCopy ($.Values.packages.istioGateway.values.gateways | default dict) -}}
  {{- $sharedGatewayValues := deepCopy ($.Values.packages.istioGateway.values.shared | default dict) -}}
  {{- $userGatewayOverrides := deepCopy $userGateways -}}
  {{- $defaults := include "bigbang.defaults.istio-gateway" $ | fromYaml -}}
  {{- $istioPodAnnotations := (include "istioAnnotation" $ | fromYaml) | default dict -}}

  {{- $defaultImagePullConfig := dict
    "imagePullPolicy" .Values.imagePullPolicy
    "imagePullSecrets" (ternary (list (dict "name" "private-registry")) (list) (not (empty (include "imagePullSecret" $))))
  -}}

  {{- $enabledGateways := dict -}}
  
  {{- range $name, $mergedGW := merge $userGateways $defaults.gateways }}
    {{- if and $name $mergedGW }}
      {{- $defaultGW := deepCopy (get $defaults.gateways $name | default dict) -}}
      {{- $userGW := deepCopy (get $userGatewayOverrides $name | default dict) -}}
      {{- $effectiveGW := mergeOverwrite $defaultGW (deepCopy $sharedGatewayValues) -}}
      {{- $effectiveGW = mergeOverwrite $effectiveGW $userGW -}}
      {{- $gwType := dig "upstream" "labels" "istio" "" $effectiveGW -}}
      
      {{- if not (has $gwType (list "ingressgateway" "egressgateway")) }}
        {{- fail (printf "istio-gateway: Gateway '%s' does not have a valid type; upstream.labels.istio must be one of 'ingressgateway' or 'egressgateway'" $name) -}}
      {{ end -}}
      
      {{- $gwRecord := dict -}}
      {{- $gwRecord = set $gwRecord "serviceName" (printf "%s-%s" $name $gwType) -}}
      {{- $gwRecord = set $gwRecord "type" $gwType -}}
      
      {{- $gwDefaults := deepCopy (get $defaults.gateways $name | default dict) -}}
      {{- /*
        Give every gateway the same upstream.serviceAccount default that
        `public` and `passthrough` get out of the box. bb-common assumes a
        principal of '<gatewayName>-ingressgateway-service-account'
        so making this the umbrella default for ALL gateways means
        user-defined gateways behave the same as the built-in ones.
        User overlays still win because they are applied
        after `defaults` in the HelmRelease valuesFrom chain.
      */ -}}
      {{- $defaultSA := printf "%s-ingressgateway-service-account" $gwRecord.serviceName -}}
      {{- $defaultUpstreamValues := dict "serviceAccount" (dict "create" true "name" $defaultSA) -}}
      {{- if $istioPodAnnotations }}
        {{- $defaultUpstreamValues = set $defaultUpstreamValues "podAnnotations" $istioPodAnnotations -}}
      {{- end }}
      {{- $gwDefaults = mergeOverwrite $gwDefaults (dict "upstream" $defaultUpstreamValues) -}}
      {{- if $gwDefaults }}
        {{- $gwRecord = set $gwRecord "defaults" $gwDefaults -}}
      {{ end -}}
      
      {{- $gwOverlays := mustMergeOverwrite (deepCopy $sharedGatewayValues) (deepCopy (dig "gateways" $name dict $.Values.packages.istioGateway.values)) -}}
      {{- if $gwOverlays }}
        {{- $gwOverlays = mustMergeOverwrite (dict "upstream" (deepCopy $defaultImagePullConfig)) $gwOverlays -}}
        {{- if $istioPodAnnotations }}
          {{- $gwOverlays = mergeOverwrite $gwOverlays (dict "upstream" (dict "podAnnotations" $istioPodAnnotations)) -}}
        {{- end }}
        {{- $gwRecord = set $gwRecord "overlays" $gwOverlays -}}
      {{ end -}}
      
      {{- $enabledGateways = set $enabledGateways $name $gwRecord -}}
    {{ end -}}
  {{ end -}}
  
  {{- range $name, $gw := $.Values.packages.istioGateway.values.gateways }}
    {{- if kindIs "map" $gw }}
      {{- if eq (len $gw) 0 }}
        {{- $enabledGateways = unset $enabledGateways $name -}}
      {{ end -}}
    {{- else -}}
      {{- $enabledGateways = unset $enabledGateways $name -}}
    {{ end -}}
  {{ end -}}
  
  {{ toYaml $enabledGateways }}
{{- end -}}

{{/*
bigbang.addValueIfSet can be used to nil check parameters before adding them to the values.
  Expects a list with the following params:
    * [0] - (string) <yaml_key_to_add>
    * [1] - (interface{}) <value_to_check>

  No output is generated if <value> is undefined, however, explicitly set empty values
  (i.e. `username=""`) will be passed along. All string fields will be quoted.

  Example command:
  - `{{ (list "name" .username) | include "bigbang.addValueIfSet" }}`
    * When `username: Aniken`
      -> `name: "Aniken"`
    * When `username: ""`
      -> `name: ""`
    * When username is not defined
      -> no output
*/}}
{{- define "bigbang.addValueIfSet" -}}
  {{- $key := (index . 0) }}
  {{- $value := (index . 1) }}
  {{- /*If the value is explicitly set (even if it's empty)*/}}
  {{- if not (kindIs "invalid" $value) }}
    {{- /*Handle strings*/}}
    {{- if kindIs "string" $value }}
      {{- printf "\n%s" $key }}: {{ $value | quote }}
    {{- /*Hanldle slices*/}}
    {{- else if kindIs "slice" $value }}
      {{- printf "\n%s" $key }}:
        {{- range $value }}
          {{- if kindIs "string" . }}
            {{- printf "\n  - %s" (. | quote) }}
          {{- else }}
            {{- printf "\n  - %v" . }}
          {{- end }}
        {{- end }}
    {{- /*Handle other types (no quotes)*/}}
    {{- else }}
      {{- printf "\n%s" $key }}: {{ $value }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Annotation to force pods to restart on Istio dataplane changes.
In ambient mode emits the dataplane annotation so pods roll when ambient is
toggled; otherwise emits the Istio version so sidecar pods roll on upgrade.
*/}}
{{- define "istioAnnotation" -}}
{{- if eq (include "ambientEnabled" .) "true" -}}
bigbang.dev/istioDataplane: ambient
{{- else -}}
{{- $istiod := .Values.packages.istiod | default dict -}}
{{- if (eq ($istiod.sourceType | default "git") "git") -}}
{{- $git := $istiod.git | default dict -}}
{{- if $git.semver -}}
bigbang.dev/istioVersion: {{ $git.semver | trimSuffix (regexFind "-bb.*" $git.semver) }}
{{- else if $git.tag -}}
bigbang.dev/istioVersion: {{ $git.tag | trimSuffix (regexFind "-bb.*" $git.tag) }}
{{- else if $git.branch -}}
bigbang.dev/istioVersion: {{ $git.branch }}
{{- end -}}
{{- else -}}
{{- $helmRepo := $istiod.helmRepo | default dict -}}
{{- if $helmRepo.tag -}}
bigbang.dev/istioVersion: {{ $helmRepo.tag }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- /* Helpers below this line are in support of the Big Bang extensibility feature */ -}}

{{- /* Converts the string in . to a legal Kubernetes resource name */ -}}
{{- define "resourceName" -}}
  {{- regexReplaceAll "\\W+" . "-" | trimPrefix "-" | trunc 63 | trimSuffix "-" | kebabcase -}}
{{- end -}}

{{- /* Returns a space separated string of unique namespaces where `<package>.enabled` and key held in `.constraint` are true */ -}}
{{- /* [Optional] Set `.constraint` to the key under <package> holding a boolean that must be true to be enabled */ -}}
{{- /* [Optional] Set `.default` to `true` to enable a `true` result when the `constraint` key is not found */ -}}
{{- /* To use: $ns := compact (splitList " " (include "uniqueNamespaces" (merge (dict "constraint" "some.boolean" "default" true) .))) */ -}}
{{- define "uniqueNamespaces" -}}
  {{- $namespaces := list -}}
  {{- range $pkg, $vals := (.Values._customPackages | default dict) -}}
    {{- if (dig "enabled" true $vals) -}}
      {{- $constraint := $vals -}}
      {{- range $key := split "." (default "" $.constraint) -}}
        {{- $constraint = (dig $key dict $constraint) -}}
      {{- end -}}
      {{- if (ternary $constraint (default false $.default) (kindIs "bool" $constraint)) -}}
        {{- $namespaces = append $namespaces (dig "namespace" "name" (include "resourceName" $pkg) $vals) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- join " " (uniq $namespaces) | trim -}}
{{- end -}}

{{- /* Prints istio version */ -}}
{{- define "istioVersion" -}}
  {{- regexReplaceAll "-bb.+$" (coalesce .Values.packages.istiod.git.semver .Values.packages.istiod.git.tag .Values.packages.istiod.git.branch) "" -}}
{{- end -}}

{{- /* Returns an SSO host */ -}}
{{- define "sso.host" -}}
  {{- coalesce .Values.sso.oidc.host (regexReplaceAll ".*//([^/]*)/?.*" .Values.sso.url "${1}") -}}
{{- end -}}

{{- /* Returns an SSO realm */ -}}
{{- define "sso.realm" -}}
  {{- coalesce .Values.sso.oidc.realm (regexReplaceAll ".*/realms/([^/]*)" .Values.sso.url "${1}") (regexReplaceAll "\\W+" .Values.sso.name "") -}}
{{- end -}}

{{- /* Returns the SSO base URL */ -}}
{{- define "sso.url" -}}
  {{- if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "https://%s/auth/realms/%s" .Values.sso.oidc.host .Values.sso.oidc.realm -}}
  {{- else -}}
    {{- tpl (default "" .Values.sso.url) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the SSO auth url (OIDC) */ -}}
{{- define "sso.oidc.auth" -}}
  {{- if .Values.sso.auth_url -}}
    {{- tpl (default "" .Values.sso.auth_url) . -}}
  {{- else if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/protocol/openid-connect/auth" (include "sso.url" .) -}}
  {{- else -}}
    {{- tpl (dig "oidc" "authorization" (printf "%s/protocol/openid-connect/auth" (include "sso.url" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the SSO token url (OIDC) */ -}}
{{- define "sso.oidc.token" -}}
  {{- if .Values.sso.token_url -}}
    {{- tpl (default "" .Values.sso.token_url) . -}}
  {{- else if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/protocol/openid-connect/token" (include "sso.url" .) -}}
  {{- else -}}
    {{- tpl (dig "oidc" "token" (printf "%s/protocol/openid-connect/token" (include "sso.url" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the SSO userinfo url (OIDC) */ -}}
{{- define "sso.oidc.userinfo" -}}
  {{- if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/protocol/openid-connect/userinfo" (include "sso.url" .) -}}
  {{- else -}}
    {{- tpl (dig "oidc" "userinfo" (printf "%s/protocol/openid-connect/userinfo" (include "sso.url" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the SSO jwks url (OIDC) */ -}}
{{- define "sso.oidc.jwksuri" -}}
  {{- if .Values.sso.jwks_uri -}}
    {{- tpl (default "" .Values.sso.jwks_uri) . -}}
  {{- else if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/protocol/openid-connect/certs" (include "sso.url" .) -}}
  {{- else -}}
    {{- tpl (dig "oidc" "jwksUri" (printf "%s/protocol/openid-connect/certs" (include "sso.url" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the SSO end session url (OIDC) */ -}}
{{- define "sso.oidc.endsession" -}}
  {{- if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/protocol/openid-connect/logout" (include "sso.url" .) -}}
  {{- else -}}
    {{- tpl (dig "oidc" "endSession" (printf "%s/protocol/openid-connect/logout" (include "sso.url" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the single sign on service (SAML) */ -}}
{{- define "sso.saml.service" -}}
  {{- if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/protocol/saml" (include "sso.url" .) -}}
  {{- else -}}
    {{- tpl (dig "saml" "service" (printf "%s/protocol/saml" (include "sso.url" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the single sign on entity descriptor (SAML) */ -}}
{{- define "sso.saml.descriptor" -}}
  {{- if and .Values.sso.oidc.host .Values.sso.oidc.realm -}}
    {{- printf "%s/descriptor" (include "sso.saml.service" .) -}}
  {{- else -}}
    {{- tpl (dig "saml" "entityDescriptor" (printf "%s/descriptor" (include "sso.saml.service" .)) .Values.sso) . -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the signing cert (no headers) from the SAML metadata */ -}}
{{- define "sso.saml.cert" -}}
  {{- $cert := dig "saml" "metadata" "" .Values.sso -}}
  {{- if $cert -}}
    {{- $cert := regexFind "<md:IDPSSODescriptor[\\s>][\\s\\S]*?</md:IDPSSODescriptor[\\s>]" $cert -}}
    {{- $cert = regexFind "<md:KeyDescriptor[\\s>][^>]*?use=\"signing\"[\\s\\S]*?</md:KeyDescriptor[\\s>]" $cert -}}
    {{- $cert = regexFind "<ds:KeyInfo[\\s>][\\s\\S]*?</ds:KeyInfo[\\s>]" $cert -}}
    {{- $cert = regexFind "<ds:X509Data[\\s>][\\s\\S]*?</ds:X509Data[\\s>]" $cert -}}
    {{- $cert = regexFind "<ds:X509Certificate[\\s>][\\s\\S]*?</ds:X509Certificate[\\s>]" $cert -}}
    {{- $cert = regexReplaceAll "<ds:X509Certificate[^>]*?>\\s*([\\s\\S]*?)</ds:X509Certificate[\\s>]" $cert "${1}" -}}
    {{- $cert = regexReplaceAll "\\s*" $cert "" -}}
    {{- required "X.509 signing certificate could not be found in sso.saml.metadata!" $cert -}}
  {{- end -}}
{{- end -}}

{{- /* Returns the signing cert with headers from the SAML metadata */ -}}
{{- define "sso.saml.cert.withheaders" -}}
  {{- $cert := include "sso.saml.cert" . -}}
  {{- if $cert -}}
    {{- printf "-----BEGIN CERTIFICATE-----\n%s\n-----END CERTIFICATE-----" $cert -}}
  {{- end -}}
{{- end -}}

{{- /*
Returns the git credentails secret for the given scope and name
*/ -}}
{{- define "gitCredsSecret" -}}
{{- $name := include "resourceName" .name }}
{{- $releaseName := .releaseName }}
{{- $releaseNamespace := .releaseNamespace }}
{{- $enabled := .targetScope.enabled }}
{{- if hasKey . "enabled" }}
{{- $enabled = .enabled }}
{{- end }}
{{- with .targetScope -}}
{{- if and (eq .sourceType "git") $enabled }}
{{- if .git }}
{{- with .git -}}
{{- if not .existingSecret }}
{{- if .credentials }}
{{- if coalesce  .credentials.username .credentials.password .credentials.caFile .credentials.privateKey .credentials.publicKey .credentials.knownHosts -}}
{{- $http := coalesce .credentials.username .credentials.password .credentials.caFile "" }}
{{- $ssh := coalesce .credentials.privateKey .credentials.publicKey .credentials.knownHosts "" }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ $releaseName }}-{{ $name }}-git-credentials
  namespace: {{ $releaseNamespace }}
type: Opaque
data:
  {{- if $http }}
  {{- if .credentials.caFile }}
  caFile: {{ .credentials.caFile | b64enc }}
  {{- end }}
  {{- if and .credentials.username  (not .credentials.password ) }}
  {{- printf "%s - When using http git username, password must be specified" $name | fail }}
  {{- end }}
  {{- if and .credentials.password  (not .credentials.username ) }}
  {{- printf "%s - When using http git password, username must be specified" $name | fail }}
  {{- end }}
  {{- if and .credentials.username .credentials.password }}
  username: {{ .credentials.username | b64enc }}
  password: {{ .credentials.password | b64enc }}
  {{- end }}
  {{- else }}
  {{- if not (and (and .credentials.privateKey .credentials.publicKey) .credentials.knownHosts) }}
  {{- printf "%s - When using ssh git credentials, privateKey, publicKey, and knownHosts must all be specified" $name | fail }}
  {{- end }}
  identity: {{ .credentials.privateKey | b64enc }}
  identity.pub: {{ .credentials.publicKey | b64enc }}
  known_hosts: {{ .credentials.knownHosts | b64enc }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Shared HelmRelease chart spec block.
Generates the spec.chart.spec section handling git vs helmRepo sources with cosign verification.
Args (dict):
  - name: GitRepository/sourceRef name (kebab-case, e.g. "kyverno-policies")
  - package: the package values object (contains sourceType, git, helmRepo)
  - root: root context ($ or .)
*/}}
{{- define "bigbang.helmRelease.chartSpec" -}}
{{- if and .emitReleaseName (dig "releaseName" "" .package) }}
releaseName: {{ .package.releaseName }}
{{- end }}
chart:
  spec:
    {{- if eq .package.sourceType "git" }}
    chart: {{ .package.git.path }}
    sourceRef:
      kind: GitRepository
      name: {{ .name }}
      namespace: {{ .root.Release.Namespace }}
    {{- else }}
    chart: {{ .package.helmRepo.chartName }}
    version: {{ .package.helmRepo.tag }}
    sourceRef:
      kind: HelmRepository
      name: {{ .package.helmRepo.repoName }}
      namespace: {{ .root.Release.Namespace }}
    {{- $repoType := include "getRepoType" (dict "repoName" .package.helmRepo.repoName "allRepos" .root.Values.helmRepositories) -}}
    {{- if (and .package.helmRepo.cosignVerify (eq $repoType "oci")) }} # Needs to be an OCI repo
    verify:
      provider: cosign
      secretRef:
        name: {{ printf "%s-cosign-pub" .package.helmRepo.repoName }}
    {{- end }}
    {{- end }}
    interval: 5m
{{- end -}}

{{/*
Returns "true" when at least one metric scraper is active:
  - Prometheus scraping (monitoring.enabled + prometheusMetrics.enabled)
  - Alloy metrics scraping (alloy.enabled + alloyMetrics.enabled)
Used to gate ServiceMonitor/PodMonitor CRD creation across all packages.
*/}}
{{- define "metricScrapingEnabled" -}}
{{- or (and .Values.packages.monitoring.enabled (dig "prometheusMetrics" "enabled" true .Values.packages.monitoring)) (and .Values.packages.alloy.enabled (dig "alloyMetrics" "enabled" false .Values.packages.alloy)) -}}
{{- end -}}

{{/*
Shared HelmRelease valuesFrom block.
Generates the standard 3-secret valuesFrom (common, defaults, overlays).
Args (dict):
  - name: secret name suffix (e.g. "loki", "ek", "metrics")
  - root: root context ($ or .)
*/}}
{{- define "bigbang.helmRelease.valuesFrom" -}}
valuesFrom:
  - name: {{ .root.Release.Name }}-{{ .name }}-values
    kind: Secret
    valuesKey: "common"
  - name: {{ .root.Release.Name }}-{{ .name }}-values
    kind: Secret
    valuesKey: "defaults"
  - name: {{ .root.Release.Name }}-{{ .name }}-values
    kind: Secret
    valuesKey: "overlays"
{{- end -}}

{{- /* Returns type of Helm Repository */ -}}
{{- define "getRepoType" -}}
  {{- $repoName := .repoName -}}
  {{- range .allRepos -}}
    {{- if eq .name $repoName -}}
      {{- print .type -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- /* Returns whether an optional package is enabled without assuming its map exists. */ -}}
{{- define "packageEnabled" -}}
{{- $packages := default (dict) .root.Values.packages -}}
{{- $package := default (dict) (get $packages .name) -}}
{{- default false (get $package "enabled") }}
{{- end -}}

{{- /* Returns true if istiod is enabled */ -}}
{{- define "istioEnabled" -}}
{{- $packages := default (dict) .Values.packages -}}
{{- $istiod := default (dict) (get $packages "istiod") -}}
{{ dig "enabled" false $istiod }}
{{- end -}}

{{- /* Returns true when authservice should be deployed or referenced by integrations. */ -}}
{{- define "authserviceEnabled" -}}
{{- and
  (eq (include "istioEnabled" .) "true")
  (or
    .Values.packages.authservice.enabled
    (and .Values.packages.monitoring.enabled .Values.packages.monitoring.sso.enabled)
    (and .Values.packages.tempo.enabled .Values.packages.tempo.sso.enabled)
    (and .Values.packages.thanos.enabled .Values.packages.thanos.sso.enabled)
  )
-}}
{{- end -}}

{{- /* Returns true if ambient mode is enabled (via ztunnel or global ambient flag) */ -}}
{{- define "ambientEnabled" -}}
{{- $packages := default (dict) .Values.packages -}}
{{- $ztunnel := default (dict) (get $packages "ztunnel") -}}
{{- $istio := default (dict) .Values.istio -}}
{{- $ambient := default (dict) (get $istio "ambient") -}}
{{ or (default false (get $ztunnel "enabled")) (default false (get $ambient "enabled")) }}
{{- end -}}

{{- /* Returns true if the shared egress gateway is enabled (via istioEgressGateway package or global egressGateway flag) */ -}}
{{- define "egressGatewayEnabled" -}}
{{ or .Values.packages.istioEgressGateway.enabled .Values.istio.egressGateway.enabled }}
{{- end -}}

{{- /*
Returns "true" when Monitoring's prometheus/alertmanager should be protected by
authservice via the monitoring package's own ambient waypoint (the bb-common
per-route authservice model). This replaces the legacy model that enrolled the
Services onto the shared authservice-namespace waypoint. Only applies in ambient
mode; sidecar-mode SSO keeps the legacy pod-label ext_authz path.
*/ -}}
{{- define "monitoring.authservice.waypointEnabled" -}}
{{- and
  (eq (include "ambientEnabled" .) "true")
  (eq (include "authserviceEnabled" .) "true")
  .Values.packages.monitoring.enabled
  .Values.packages.monitoring.sso.enabled
-}}
{{- end -}}

{{- /*
Returns "true" when Thanos's query-frontend should be protected by authservice via
the thanos package's own ambient waypoint (the bb-common per-route authservice
model). This replaces the legacy model that enrolled the Service onto the shared
authservice-namespace waypoint. Only applies in ambient mode; sidecar-mode SSO
keeps the legacy pod-label ext_authz path.
*/ -}}
{{- define "thanos.authservice.waypointEnabled" -}}
{{- and
  (eq (include "ambientEnabled" .) "true")
  (eq (include "authserviceEnabled" .) "true")
  .Values.packages.thanos.enabled
  .Values.packages.thanos.sso.enabled
-}}
{{- end -}}

{{- /* Returns "true" if networkPolicies should be enabled for a package.
       True when .Values.networkPolicies.enabled is true OR ambient mode is enabled.
       Ambient mode requires bb-common's network-policies render to run because the
       AuthorizationPolicies that grant cross-namespace traffic on ambient workloads
       are generated alongside the NetworkPolicies (via generateFromNetpol).
    */ -}}
{{- define "networkPoliciesEnabled" -}}
{{ or .Values.networkPolicies.enabled (eq (include "ambientEnabled" .) "true") }}
{{- end -}}

{{- /* Returns "true" if authorization policies should be generated.
       True when legacy package-level istio.hardened is enabled, the global
       authorizationPolicies switch is enabled, or ambient mode is enabled.
       Args (positional list):
         0 - pkg:  the package's values dict (e.g. .Values.packages.loki.values, .Values.packages.argocd.values)
         1 - root: the root context (.)
    */ -}}
{{- define "authorizationPoliciesEnabled" -}}
{{- $pkg  := index . 0 -}}
{{- $root := index . 1 -}}
{{- $authorizationPoliciesEnabled := or
  (dig "istio" "hardened" "enabled" false $pkg)
  $root.Values.authorizationPolicies.enabled
-}}
{{- $ambient  := eq (include "ambientEnabled" $root) "true" -}}
{{ or $authorizationPoliciesEnabled $ambient }}
{{- end -}}

{{- /* Returns the `istio` and `networkPolicies` bb-common scaffolding shared by nearly
       every package (istio.enabled/sidecar/ambient/authorizationPolicies,
       networkPolicies.enabled/hbonePortInjection, and the ingress/egress definitions
       passthrough of the globally-configured network-policy definitions). Called from
       `values-secret`, which deep-merges this baseline underneath each package's own
       `defaults`, so a package only needs to declare the fields that diverge from the
       baseline (e.g. gatekeeper and kyverno hardcode hbonePortInjection.enabled: false
       to opt out of ambient's HBONE injection) or that extend it (e.g. vault adds an
       extra entry alongside the global ingress definitions; kiali/grafana add
       ingress/egress `defaults`, `from`, `to` siblings). Because values-secret merges
       maps key-by-key rather than replacing them wholesale, a package adding one extra
       definitions entry doesn't need to restate the global ones.
       Args (positional list):
         0 - pkg:    the package's values dict (e.g. .Values.packages.loki.values, .Values.packages.argocd.values)
         1 - pkgTop: the package's top-level dict (e.g. .Values.packages.loki, .Values.packages.argocd) — used
                     only for istio.injection, which is a top-level user knob, unlike the rest of
                     this block which reads from `.values`
         2 - root:   the root context (.)
    */ -}}
{{- define "bigbang.commonPackageDefaults" -}}
{{- $pkg    := index . 0 -}}
{{- $pkgTop := index . 1 -}}
{{- $root   := index . 2 -}}
{{- $hardened := or (dig "istio" "hardened" "enabled" false $pkg) (dig "hardened" "enabled" false $root.Values.packages.istiod.values) -}}
istio:
  enabled: {{ eq (include "istioEnabled" $root) "true" }}
  sidecar:
    enabled: {{ and $hardened (ne (include "ambientEnabled" $root) "true") }}
  ambient:
    enabled: {{ include "ambientEnabled" $root }}
  injection: {{ ternary "disabled" (dig "istio" "injection" "enabled" $pkgTop) (eq (include "ambientEnabled" $root) "true") }}
  authorizationPolicies:
    enabled: {{ include "authorizationPoliciesEnabled" (list $pkg $root) }}
    generateFromNetpol: {{ include "authorizationPoliciesEnabled" (list $pkg $root) }}
networkPolicies:
  enabled: {{ include "networkPoliciesEnabled" $root }}
  hbonePortInjection:
    enabled: {{ include "ambientEnabled" $root }}
  ingress:
    definitions: {{ $root.Values.networkPolicies.ingress.definitions | toYaml | nindent 6 }}
  egress:
    definitions: {{ $root.Values.networkPolicies.egress.definitions | toYaml | nindent 6 }}
{{- end -}}

{{- /* Top-level routes.defaults passthrough, nested under a package's routes block.
       Included per-package (only packages on a bb-common release with routes.defaults
       support) until every bb-common package supports it; then fold this into
       bigbang.commonPackageDefaults.
       outbound.egressGateway is blanked unless ambient and the egress gateway package
       are both enabled, so ServiceEntries are never bound to a waypoint that will not
       exist (Istio fails open and traffic would egress directly). */ -}}
{{- define "bigbang.routeDefaults" -}}
{{- $routeDefaults := dig "defaults" dict (.Values.routes | default dict) }}
{{- $egressGatewayActive := and (eq (include "ambientEnabled" .) "true") (eq (include "egressGatewayEnabled" .) "true") }}
defaults:
  {{- with dig "inbound" "gateways" list $routeDefaults }}
  inbound:
    gateways: {{ . | toYaml | nindent 6 }}
  {{- end }}
  outbound:
    egressGateway: {{ ternary (dig "outbound" "egressGateway" false $routeDefaults) false $egressGatewayActive }}
{{- end -}}

{{- /*
Returns "true" if ServiceMonitor should use mTLS for scraping Istio-injected pods.
Checks: global istio enabled, package istio enabled, injection enabled, not ambient mode, and mTLS STRICT mode.
This typically gates the creation of a ServiceMonitor tlsConfig with istio-provided certs for scraping metrics from Istio-injected pods.
insecureSkipVerify will be set to true in the tlsConfig because Prometheus does not support Istio security naming, thus skipping verifying the target pod certificate
If any of the conditions are not met, the ServiceMonitor will be created without the tlsConfig
Args (list):
  - [0] pkg: the package config (e.g. .Values.packages.loki)
  - [1] root: root context ($)
Usage: {{- if eq (include "metricsSidecarMtls" (list .Values.packages.loki .)) "true" }}
*/ -}}
{{- define "metricsSidecarMtls" -}}
{{- $pkg := index . 0 -}}
{{- $root := index . 1 -}}
{{- $globalIstioEnabled := eq (include "istioEnabled" $root) "true" -}}
{{- $pkgIstioEnabled := dig "values" "istio" "enabled" true $pkg -}}
{{- $injectionEnabled := ne (dig "istio" "injection" "enabled" $pkg) "disabled" -}}
{{- $ambientEnabled := eq (include "ambientEnabled" $root) "true" -}}
{{- $mtlsStrict := eq (dig "values" "istio" "mtls" "mode" "STRICT" $pkg) "STRICT" -}}
{{- and $globalIstioEnabled $pkgIstioEnabled $injectionEnabled (not $ambientEnabled) $mtlsStrict -}}
{{- end -}}

{{- /* Returns dependsOn entries for Istio HelmReleases. */ -}}
{{- define "istioHelmReleases" -}}
- name: istiod
  namespace: {{ .Release.Namespace }}
{{- if or .Values.packages.istioCNI.enabled (eq (include "ambientEnabled" .) "true") }}
- name: istio-cni
  namespace: {{ .Release.Namespace }}
{{- end }}
{{- if eq (include "ambientEnabled" .) "true" }}
- name: ztunnel
  namespace: {{ .Release.Namespace }}
- name: gateway-api
  namespace: {{ .Release.Namespace }}
{{- end }}
{{- end -}}

{{/* Render user-supplied additive HelmRelease dependency entries. Called from the else-if additive branch only; never used in the dependsOnOverride replacement path. */}}
{{- define "bigbang.helmRelease.dependsOn" -}}
{{- with (dig "dependsOn" list .) -}}
{{- toYaml . -}}
{{- end -}}
{{- end -}}

{{- /* Returns name of istio Namespace Selector*/ -}}
{{- define "istioNamespaceSelector" -}}
ingress: istio-gateway
egress: istio-system
{{- end -}}

{{- /*
Gets the gateway selector configuration for a package
Args:
    - default: The default gateway name to use if none specified (default: "public")
    - pkg: The package values (e.g. .Values.packages.argocd)
    - root: The root context
*/}}
{{- define "getGatewaySelector" -}}
{{- $default := default "public" .default }}
{{- $gateway := default $default .pkg.ingress.gateway }}
{{- $gateways := (include "enabledGateways" .root) | fromYaml }}
{{- $gw := get $gateways $gateway }}
{{- if $gw }}
  {{- toYaml (dict "app" $gw.serviceName "istio" "ingressgateway") }}
{{- end }}
{{- end -}}

{{- /*
Gets the gateway name for a package
Args:
    - default: The default gateway name to use if none specified (default: "public")
    - gateway: The gateway name
    - root: The root context
*/}}
{{- define "getGatewayName" -}}
{{- $default := default "public" .default }}
{{- $gateway := default $default .gateway }}
{{- $gateways := (include "enabledGateways" .root) | fromYaml }}
{{- $gwlookup := get $gateways $gateway }}
{{- $gw := default (dict "serviceName" $default) $gwlookup }}
{{- printf "istio-gateway/%s" $gw.serviceName }}
{{- end -}}

{{- define "bigbang.istio-gateway.ingress-netpol-spec" }}
  {{- $ctx := index . 0 }}
  {{- $name := index . 1 }}
  {{- $ports := index . 2 }}
networkPolicies:
  enabled: {{ $ctx.Values.networkPolicies.enabled }}
  ingress:
    {{- if dig "ingress" "definitions" dict $ctx.Values.networkPolicies }}
    definitions:
      {{- $ctx.Values.networkPolicies.ingress.definitions | toYaml | nindent 8 }}
    {{- end }}
    to:
      "{{ $name }}-ingressgateway:{{ $ports | toJson }}":
        from:
          definition:
            load-balancer-subnets: true
  egress:
    {{- if dig "egress" "definitions" dict $ctx.Values.networkPolicies }}
    definitions:
      {{- $ctx.Values.networkPolicies.egress.definitions | toYaml | nindent 8 }}
    {{- end }}
    from:
      "{{ $name }}-ingressgateway":
        to:
          k8s:
            '*': true
{{- end }}

{{- /*
  This helper generates a bb-common compatible netpol spec from the configured
  gateway servers of the individual gateways, then ensures that spec is applied 
  to the default values for each of the gateway releases.
*/}}
{{- define "bigbang.istio-gateway.generate-ingress-netpols" }}
  {{- $ctx := index . 0 }}
  {{- $gateways := index . 1 }}

  {{- $newGateways := dict }}

  {{- range $name, $gateway := $gateways }}
    {{- $newGateway := deepCopy $gateway }}
    {{- $mergedGateway := merge ($newGateway.overlays | default dict) ($newGateway.defaults | default dict) }}
    {{- $ports := list }}
    {{- range $server := $mergedGateway.gateway.servers }}
      {{- $ports = append $ports $server.port.number }}
    {{- end }}

    {{- $newGateway = merge (dict "defaults" (include "bigbang.istio-gateway.ingress-netpol-spec" (list $ctx $name $ports) | fromYaml)) $newGateway }}

    {{- $_ := set $newGateways $name $newGateway }}
  {{- end }}

  {{- $newGateways | toYaml }}
{{- end }}

{{- /* 
  This helper is used for packages that perform testing against keycloak when enabled
*/}}
{{- define "bigbang.cypressKeycloakValues" }}
{{- $pkg := .package -}}
{{- $values := .values -}}
{{- $enabled := dig "sso" "enabled" false $pkg -}}
{{- /* These packages expose SSO testing without an application-level SSO switch. */ -}}
{{- if (.testOnly | default false) -}}
  {{- $requested := dig "values" "bbtests" "cypress" "envs" "cypress_sso_test_requested" false $pkg -}}
  {{- $enabled = eq (toString $requested) "true" -}}
{{- end -}}
cypress_keycloak_test_enable: {{ and $values.packages.keycloak.enabled $enabled | quote }}
cypress_keycloak_url: {{ printf "https://keycloak.%s/" $values.domain | quote }}
cypress_tnr_username: {{ dig "bbtests" "cypress" "envs" "cypress_tnr_username" "cypress" $values.packages.keycloak.values | quote }}
cypress_tnr_password: {{ dig "bbtests" "cypress" "envs" "cypress_tnr_password" "tnr_w!G33ZyAt@C8" $values.packages.keycloak.values | quote }}
{{- end }}

#######################################################################################################################################
# convert the bool to string if found
#######################################################################################################################################

{{- define "bb._isTrue" -}}
  {{- $v := . -}}
  {{- if kindIs "bool" $v -}}
    {{- if $v }}true{{- end -}}
  {{- else if kindIs "string" $v -}}
    {{- if eq (lower $v) "true" }}true{{- end -}}
  {{- end -}}
{{- end -}}

#######################################################################################################################################
# Verify if there is a value enabled for redis or redis-bb set to true or false and if there is it will return true
#######################################################################################################################################

{{- define "bb.anyRedisEnabled" -}}
  {{- $n := . -}}
  {{- if kindIs "map" $n -}}
    {{- $m := default dict $n -}}              {{/* ensure non-nil map */}}
    {{- $r := default dict (get $m "redis") -}}
    {{- $rb := default dict (get $m "redis-bb") -}}
    {{- if or
          (eq (include "bb._isTrue" (get $r  "enabled")) "true")
          (eq (include "bb._isTrue" (get $rb "enabled")) "true")
        -}}
      true
    {{- else -}}
      {{- $found := "" -}}
      {{- range $k, $v := $m -}}
        {{- if eq (include "bb.anyRedisEnabled" $v) "true" -}}
          {{- $found = "true" -}}
        {{- end -}}
      {{- end -}}
      {{- if eq $found "true" -}}true{{- end -}}
    {{- end -}}
  {{- else if kindIs "slice" $n -}}
    {{- $found := "" -}}
    {{- range $i, $v := $n -}}
      {{- if eq (include "bb.anyRedisEnabled" $v) "true" -}}
        {{- $found = "true" -}}
      {{- end -}}
    {{- end -}}
    {{- if eq $found "true" -}}true{{- end -}}
  {{- end -}}
{{- end -}}

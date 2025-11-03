{{- define "values-bigbang" -}}
{{- /*
 * bigbang.values-bigbang: Produce a stripped version of the bigbang variables
 * in the root namespace suitable for inclusion in wrapper or package variables definitions
 */ -}}
{{ toYaml (pick $ "domain" "openshift") }}
{{- /* For every top level map, if it has the enable key, pass it through. */ -}}
{{- range $bbpkg, $bbvals := $ -}}
  {{- if kindIs "map" $bbvals -}}
    {{- if hasKey $bbvals "enabled" }}
{{ $bbpkg }}:
      {{- /* For network policies, we need all of its values. */ -}}
      {{- if eq $bbpkg "networkPolicies" -}}
        {{- toYaml $bbvals | nindent 2}}
      {{- else }}
  enabled: {{ $bbvals.enabled }}
      {{- end -}}
    {{- /* For addons, pass through the enable key. */ -}}
    {{- else if eq $bbpkg "addons" }}
{{ $bbpkg }}:
      {{- range $addpkg, $addvals := $bbvals -}}
        {{- if hasKey $addvals "enabled" }}
  {{ $addpkg }}:
    enabled: {{ $addvals.enabled }}
          {{- /* For authservice, the selector values are needed. */ -}}
          {{- if and (eq $addpkg "authservice") (or (dig "values" "selector" "key" false $addvals) (dig "values" "selector" "value" false $addvals)) }}
    values:
      selector:
              {{- if (dig "values" "selector" "key" false $addvals) }}
        key: {{ $addvals.values.selector.key }}
              {{- end -}}
              {{- if (dig "values" "selector" "value" false $addvals) }}
        value: {{ $addvals.values.selector.key }}
              {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end }}

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
      {{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
      {{- end }}
      {{- end }}
    {{- end -}}
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
  name: {{ .releaseName }}-{{ .name }}-git-credentials
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
  - values: The package values to clean (e.g. .Values.kiali.values)

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

{{- /* Remove deprecated hardened key */ -}}
{{- $cleanedIstio = unset $cleanedIstio "hardened" -}}

{{- $values = set $values "istio" $cleanedIstio -}}
{{- end -}}
{{- toYaml $values -}}
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

{{- define "values-secret" -}}
{{/* This is a workaround for passthrough charts */}}
{{/* This is temporary and will be removed in a future release */}}
{{ $origDefaults := default (dict) (fromYaml .defaults) }}
{{- $defaults := deepCopy $origDefaults }}
{{- if and (not .root.Values.disableAutomaticPassthroughValues) (not .package.disableAutomaticPassthroughValues) }}
{{- $origUpstream := dig "upstream" (dict) $defaults -}}
{{- $upstream := deepCopy $origDefaults }}
{{- if $origUpstream }}
{{- $upstream = mustMergeOverwrite (deepCopy $origDefaults) (deepCopy $origUpstream) }}
{{- end -}}
{{- $newDefaults := dict "upstream" $upstream }}
{{- $defaults = mustMergeOverwrite (deepCopy $origDefaults) $newDefaults | toYaml }}
{{- else }}
{{ $defaults = $origDefaults | toYaml }}
{{- end -}}
{{/* This is the end of the workaround */}}
{{- $packageValues := default dict .package.values -}}
{{- $commonValues := mustMergeOverwrite (deepCopy $packageValues) (deepCopy ($defaults | fromYaml)) -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .root.Release.Name }}-{{ .name }}-values
  namespace: {{ .root.Release.Namespace }}
type: generic
stringData:
  common: |
    {{- toYaml (pick $commonValues "bbtests" "istio" "networkPolicies" "sso" "waitJob") | nindent 4 }}
  defaults: {{- toYaml $defaults | nindent 4 }}
  overlays: |
    {{- toYaml .package.values | nindent 4 }}
{{- end -}}

{{- define "enabledGateways" -}}
  {{- $userGateways := deepCopy ($.Values.istioGateway.values.gateways | default dict) -}}
  {{- $defaults := include "bigbang.defaults.istio-gateway" $ | fromYaml -}}

  {{- $defaultImagePullConfig := dict
    "imagePullPolicy" .Values.imagePullPolicy
    "imagePullSecrets" (list (dict "name" "private-registry"))
  -}}

  {{- $enabledGateways := dict -}}
  
  {{- range $name, $mergedGW := merge $userGateways $defaults.gateways }}
    {{- if and $name $mergedGW }}
      {{- $gwType := dig "upstream" "labels" "istio" "" $mergedGW -}}
      
      {{- if not (has $gwType (list "ingressgateway" "egressgateway")) }}
        {{- fail (printf "istio-gateway: Gateway '%s' does not have a valid type; upstream.labels.istio must be one of 'ingressgateway' or 'egressgateway'" $name) -}}
      {{ end -}}
      
      {{- $gwRecord := dict -}}
      {{- $gwRecord = set $gwRecord "serviceName" (printf "%s-%s" $name $gwType) -}}
      {{- $gwRecord = set $gwRecord "type" $gwType -}}
      
      {{- $gwDefaults := get $defaults.gateways $name | default dict -}}
      {{- if $gwDefaults }}
        {{- $gwRecord = set $gwRecord "defaults" $gwDefaults -}}
      {{ end -}}
      
      {{- $gwOverlays := dig "gateways" $name dict $.Values.istioGateway.values -}}
      {{- if $gwOverlays }}
        {{- $gwRecord = set $gwRecord "overlays" (merge $gwOverlays (dict "upstream" $defaultImagePullConfig)) -}}
      {{ end -}}
      
      {{- $enabledGateways = set $enabledGateways $name $gwRecord -}}
    {{ end -}}
  {{ end -}}
  
  {{- range $name, $gw := $.Values.istioGateway.values.gateways }}
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
Annotation for Istio version
*/}}
{{- define "istioAnnotation" -}}
{{- if (eq .Values.istiod.sourceType "git") -}}
{{- if .Values.istiod.git.semver -}}
bigbang.dev/istioVersion: {{ .Values.istiod.git.semver | trimSuffix (regexFind "-bb.*" .Values.istiod.git.semver) }}
{{- else if .Values.istiod.git.tag -}}
bigbang.dev/istioVersion: {{ .Values.istiod.git.tag | trimSuffix (regexFind "-bb.*" .Values.istiod.git.tag) }}
{{- else if .Values.istiod.git.branch -}}
bigbang.dev/istioVersion: {{ .Values.istiod.git.branch }}
{{- end -}}
{{- else -}}
bigbang.dev/istioVersion: {{ .Values.istiod.helmRepo.tag }}
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
  {{- range $pkg, $vals := .Values.packages -}}
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
  {{- regexReplaceAll "-bb.+$" (coalesce .Values.istiod.git.semver .Values.istiod.git.tag .Values.istiod.git.branch) "" -}}
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
{{- $name := .name }}
{{- $releaseName := .releaseName }}
{{- $releaseNamespace := .releaseNamespace }}
{{- with .targetScope -}}
{{- if and (eq .sourceType "git") .enabled }}
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

{{- /* Returns type of Helm Repository */ -}}
{{- define "getRepoType" -}}
  {{- $repoName := .repoName -}}
  {{- range .allRepos -}}
    {{- if eq .name $repoName -}}
      {{- print .type -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- /* Returns true if istiod is enabled */ -}}
{{- define "istioEnabled" -}}
{{ .Values.istiod.enabled }}
{{- end -}}

{{- /* Returns the name of the Istio HelmRelease. */ -}}
{{- define "istioHelmRelease" -}}
istiod
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
    - pkg: The package values (e.g. .Values.addons.argocd)
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

############################################################################################
# Kyverno Policy merge function with deduplication
############################################################################################

{{- /* This function merges defaults in lists from above into overlays */ -}}
{{- /* The end user will not have to replicate exclusions/repos from above when providing an overlay */ -}}
{{- /* There is a hidden flag `skipOverlayMerge` that can be added to any policy to ignore the defaults */ -}}
{{- define "bigbang.overlays.kyverno-policies" -}}
  {{- $defaults := fromYaml (include "bigbang.defaults.kyverno-policies" .) -}}
  {{- $overlays := dig "values" dict .Values.kyvernoPolicies -}}

  {{- /* Global merge for exclude fields */ -}}
  {{- if and (dig "exclude" "any" list $defaults) (dig "exclude" "any" list $overlays) -}}
    {{ $_ := set $overlays.exclude "any" (concat $defaults.exclude.any $overlays.exclude.any) -}}
  {{- end -}}
  {{- if and (dig "exclude" "all" list $defaults) (dig "exclude" "all" list $overlays) -}}
    {{ $_ := set $overlays.exclude "all" (concat $defaults.exclude.all $overlays.exclude.all) -}}
  {{- end -}}

  {{- /* Policy specific merges */ -}}
  {{- range $policy, $default := $defaults.policies -}}
    {{- $overlay := (dig "policies" $policy dict $overlays) -}}

    {{- /* Only continue if an overlay matches a default constriant and hidden "skipOverlayMerge" is not set */ -}}
    {{- if and $overlay (not $overlay.skipOverlayMerge) -}}

      {{- /* Add exclude fields */ -}}
      {{- if and (dig "exclude" "any" list $default) (dig "exclude" "any" list $overlay) -}}
        {{ $_ := set $overlay.exclude "any" (concat $default.exclude.any $overlay.exclude.any) -}}
      {{- end -}}
      {{- if and (dig "exclude" "all" list $default) (dig "exclude" "all" list $overlay) -}}
        {{ $_ := set $overlay.exclude "all" (concat $default.exclude.all $overlay.exclude.all) -}}
      {{- end -}}

      {{- /* Add match fields */ -}}
      {{- if and (dig "match" "any" list $default) (dig "match" "any" list $overlay) -}}
        {{ $_ := set $overlay.match "any" (concat $default.match.any $overlay.match.any) -}}
      {{- end -}}
      {{- if and (dig "match" "all" list $default) (dig "match" "all" list $overlay) -}}
        {{ $_ := set $overlay.match "all" (concat $default.match.all $overlay.match.all) -}}
      {{- end -}}
      
      {{- /* Add parameters.allow fields */ -}}
      {{- if and (dig "parameters" "allow" list $default) (dig "parameters" "allow" list $overlay) -}}
        {{ $_ := set $overlay.parameters "allow" (concat $default.parameters.allow $overlay.parameters.allow) -}}
      {{- end -}}

      {{- /* Add parameters.disallow fields */ -}}
      {{- if and (dig "parameters" "disallow" list $default) (dig "parameters" "disallow" list $overlay) -}}
        {{ $_ := set $overlay.parameters "disallow" (concat $default.parameters.disallow $overlay.parameters.disallow) -}}
      {{- end -}}

      {{- /* Add parameters.require fields */ -}}
      {{- if and (dig "parameters" "require" list $default) (dig "parameters" "require" list $overlay) -}}
        {{ $_ := set $overlay.parameters "require" (concat $default.parameters.require $overlay.parameters.require) -}}
      {{- end -}}

      {{- /* Merge 'namespaces' list by namespace name with deduplication of pods.allow and pods.deny */ -}}
      {{- if and (hasKey $default "namespaces") (hasKey $overlay "namespaces") -}}

        {{- /* Step 1: Create a map to hold merged namespaces keyed by namespace name */ -}}
        {{- $mergedNamespaces := dict -}}

        {{- /* Step 2: Index default namespaces by name */ -}}
        {{- range $ns := $default.namespaces -}}
          {{- $_ := set $mergedNamespaces $ns.namespace (deepCopy $ns) -}}
        {{- end -}}

        {{- /* Step 3: Merge overlay namespaces into the indexed map */ -}}
        {{- range $ons := $overlay.namespaces -}}

          {{- $existing := index $mergedNamespaces $ons.namespace | default dict -}}

          {{- if $existing.namespace -}}
            {{- /* Merge and deduplicate 'pods.allow' */ -}}
            {{- $allowCombined := concat (dig "pods" "allow" list $existing) (dig "pods" "allow" list $ons) -}}
            {{- $allowUnique := dict -}}
            {{- range $item := $allowCombined -}}
              {{- $_ := set $allowUnique $item true -}}
            {{- end -}}
            {{- $allow := keys $allowUnique | sortAlpha -}}

            {{- /* Merge and deduplicate 'pods.deny' */ -}}
            {{- $denyCombined := concat (dig "pods" "deny" list $existing) (dig "pods" "deny" list $ons) -}}
            {{- $denyUnique := dict -}}
            {{- range $item := $denyCombined -}}
              {{- $_ := set $denyUnique $item true -}}
            {{- end -}}
            {{- $deny := keys $denyUnique | sortAlpha -}}

            {{- /* Set merged pods back into the existing namespace entry */ -}}
            {{- $_ := set $existing "pods" (dict "allow" $allow "deny" $deny) -}}

            {{- /* Update the mergedNamespaces map */ -}}
            {{- $_ := set $mergedNamespaces $ons.namespace $existing -}}

          {{- else -}}
            {{- /* If namespace only exists in overlay, add it directly */ -}}
            {{- $_ := set $mergedNamespaces $ons.namespace $ons -}}
          {{- end -}}

        {{- end -}}

        {{- /* Step 4: Convert the merged map back into a list */ -}}
        {{- $mergedList := list -}}
        {{- range $k, $v := $mergedNamespaces -}}
          {{- $mergedList = append $mergedList $v -}}
        {{- end -}}

        {{- /* Step 5: Set the final merged list back into the overlay */ -}}
        {{- $_ := set $overlay "namespaces" $mergedList -}}

      {{- end -}}            

    {{- end -}}
  {{- end -}}
{{ toYaml $overlays }}
{{- end }}

###############################################
# define defaults here for unit testing purpose
###############################################

{{- define "bigbang.defaults.kyverno-policies" -}}
{{- $istioEnabled := eq (include "istioEnabled" .) "true" }}
{{- $deployNodeAgent := (and .Values.addons.velero.enabled (dig "deployNodeAgent" false .Values.addons.velero.values)) }}

waitforready:
  imagePullSecrets:
  - name: private-registry

policies:
  add-default-capability-drop:
    enabled: true
    exclude:
      any:
      {{- if .Values.neuvector.enabled }}
      # Neuvector needs access to host to inspect network traffic
      - resources:
          namespaces:
          - neuvector
          names:
          - neuvector-enforcer-pod*
          - neuvector-cert-upgrader-job*
          - neuvector-controller-pod*
          - neuvector-scanner-pod*
          - neuvector-prometheus-exporter-pod*
      {{- end }}
      {{- if .Values.addons.velero.enabled }}
      - resources:
          namespaces:
          - velero
          names:
          - velero-backup-restore-test*
      {{- end }}
      {{- if .Values.addons.gitlabRunner.enabled }}
      - resources:
          namespaces:
          - gitlab-runner
          names:
          - runner*
      {{- end }}
      {{- if .Values.addons.gitlab.enabled }}
      - resources:
          namespaces:
          - gitlab
          names:
          - webservice-test-runner*
      {{- end }}
      {{- if .Values.twistlock.enabled }}
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-console*
          - twistlock-defender-ds*
          - volume-upgrade*
      {{- end }}
      {{- if .Values.addons.mimir.enabled }}
      - resources:
          namespaces:
          - mimir
          names:
          - mimir-mimir-smoke-test*
      {{- end }}
      {{- if .Values.addons.vault.enabled }}
      - resources:
          namespaces:
          - vault
          names:
          - vault-vault-job-init*
      {{- end }}

  {{- if or .Values.twistlock.enabled .Values.neuvector.enabled }}
  disallow-host-namespaces:
    exclude:
      any:
      {{- if .Values.twistlock.enabled }}
      # Twistlock, by default, does its own network monitoring. hostNetworking is enabled by default for this purpose
      # With hostNetworking enabled, Istio sidecar injection is disabled. If this function is disabled, Twistlock will
      # not be able to self monitor. If both Istio sidecar injection and TL monitoring are disabled, a security gap will
      # be created for network monitoring in Twistlock.  So, it is important to make sure at least one is enabled.
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-defender-ds*
      {{- end }}
      {{- if .Values.neuvector.enabled }}
      # Neuvector needs access to host to inspect network traffic
      - resources:
          namespaces:
          - neuvector
          names:
          - neuvector-enforcer-pod*
      {{- end }}
  {{- end }}

  {{- $nodePortIngressGateways := list }}
  {{- range $name, $values := .Values.istioGateway.values.gateways }}
  {{- if eq $values.type "NodePort" }}
  {{- $nodePortIngressGateways = append $nodePortIngressGateways $name }}
  {{- end }}
  {{- end }}

  {{- range $name, $values := .Values.istioGateway.values.gateways }}
  {{- if eq (dig "k8s" "service" "type" "LoadBalancer" $values) "NodePort" }}
  {{- $nodePortIngressGateways = append $nodePortIngressGateways $name }}
  {{- end }}
  {{- end }}

  # Istio services (istio ingress) can create type: NodePort services
  disallow-nodeport-services:
    validationFailureAction: Enforce
    {{- if or $nodePortIngressGateways .Values.istiod.enabled }}
    exclude:
      any:
      - resources:
          kinds:
          - Service
          names:
          {{- range $name := $nodePortIngressGateways }}
          - {{ $name }}
          {{- end }}
          namespaces:
          - istio-system
      {{- if and .Values.istiod.enabled .Values.istioGateway.enabled }}
      - resources:
          kinds:
          - Service
          names:
          {{- range $name, $gw := include "enabledGateways" .root | fromYaml }}
          - {{ $gw.serviceName }}
          {{ end -}}
          namespaces:
          - istio-gateway
      {{- end }}
    {{- end }}

  disallow-image-tags:
    enabled: true
    validationFailureAction: Enforce
    exclude:
      any:
      # istio/gateway sets the deployment image to `auto` by default
      # and does not expose any way for the chart consumer to modify
      # it. The idea is `istiod` will inject the correct image at
      # pod creation based on `istiod`'s proxy config.
      {{- if .Values.istioGateway.enabled }}
      - resources:
          namespaces:
          - istio-gateway
          names:
          - '*-ingressgateway'
          - '*-egressgateway'
      {{- end }}

  disallow-istio-injection-bypass:
    enabled: {{ $istioEnabled }}
    exclude:
      any:
      # Istio does not inject itself
      - resources:
          namespaces:
          - istio-system
          - istio-gateway

  disallow-namespaces:
    enabled: true
    validationFailureAction: Enforce
    parameters:
      disallow:
      - bigbang
      - default

  {{- if or .Values.fluentbit.enabled .Values.neuvector.enabled}}
  disallow-privileged-containers:
    exclude:
      any:
      {{- if .Values.fluentbit.enabled }}
      # NEEDS FURTHER JUSTIFICATION
      # Fluentbit needs privileged to read and store the buffer for tailing logs from the nodes
      - resources:
          namespaces:
          - fluentbit
          names:
          - fluentbit-fluent-bit*
      {{- end }}
      {{- if .Values.neuvector.enabled }}
      # Neuvector needs privileged access for realtime scanning of files from the node / access to the container runtime
      - resources:
          namespaces:
          - neuvector
          names:
          - neuvector-enforcer-pod*
          - neuvector-controller-pod*
          - neuvector-scanner-pod*
      {{- end }}
  {{- end }}

  # -- Prevent Automounting of Kubernetes API Credentials on Pods and Service Accounts
  disallow-auto-mount-service-account-token:
    enabled: true
    validationFailureAction: Audit
    exclude:
      any:
      {{- if .Values.kyvernoReporter.enabled }}
      - resources:
          namespaces:
          - kyverno-reporter
          kinds:
          - Pod
          - Deployment
          names:
          - kyverno-reporter*
      {{- end }}
      {{- if .Values.monitoring.enabled }}
      - resources:
          namespaces:
          - flux-system
          kinds:
          - Pod
          - Deployment
          - StatefulSet
          names:
          - notification-controller*
          - helm-controller*
          - source-controller*
          - kustomize-controller*
      {{- end }}
      {{- if .Values.addons.thanos.enabled }}
      - resources:
          namespaces:
          - thanos
          kinds:
          - Pod
          - Deployment
          - StatefulSet
          names:
          - thanos-compactor*
      {{- end }}
      {{- if .Values.addons.externalSecrets.enabled }}
      - resources:
          namespaces:
          - external-secrets
          names:
          - external-secrets*
      {{- end }}
      {{- if .Values.addons.headlamp.enabled }}
      - resources:
          namespaces:
          - headlamp
          names:
          - headlamp*
      {{- end }}
      {{- if .Values.addons.backstage.enabled }}
      - resources:
          namespaces:
          - backstage
          kinds:
          - Pod
          - Deployment
          - ReplicaSet
          - ServiceAccount
          names:
          - backstage
          - backstage*
      {{- end }}
      {{- if .Values.gatekeeper.enabled }}
      - resources:
          namespaces:
          - gatekeeper-system
          kinds:
          - Pod
          - Deployment
          names:
          - gatekeeper-audit*
          - gatekeeper-controller-manager*
      {{- end }}

  {{- if or .Values.fluentbit.enabled .Values.monitoring.enabled .Values.twistlock.enabled }}
  disallow-tolerations:
    exclude:
      any:
      {{- if .Values.fluentbit.enabled }}
      # Fluent bit needs to be able to run on all nodes to gather logs from the host for containers
      - resources:
          namespaces:
          - fluentbit
          names:
          - fluentbit-fluent-bit*
      {{- end }}
      {{- if .Values.monitoring.enabled }}
      # Prometheus Node Exporter needs to be able to run on all nodes, regardless of taint, to gather node metrics
      - resources:
          namespaces:
          - monitoring
          names:
          - monitoring-monitoring-prometheus-node-exporter*
      {{- end }}
      {{- if .Values.twistlock.enabled }}
      # In order to provide real-time scanning of all nodes, Twistlock must ignore taints
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-defender-ds*
      {{- end }}
  {{- end }}

  require-drop-all-capabilities:
    validationFailureAction: Enforce
    exclude:
      any:
      {{- if .Values.neuvector.enabled }}
      # Neuvector needs access to host to inspect network traffic
      - resources:
          namespaces:
          - neuvector
          names:
          - neuvector-enforcer-pod*
          - neuvector-cert-upgrader-job-*
          - neuvector-controller-pod*
          - neuvector-scanner-pod*
          - neuvector-prometheus-exporter-pod*
      {{- end }}
      {{- if .Values.addons.velero.enabled }}
      - resources:
          namespaces:
          - velero
          names:
          - velero-backup-restore-test*
      {{- end }}
      {{- if .Values.addons.gitlabRunner.enabled }}
      - resources:
          namespaces:
          - gitlab-runner
          names:
          - runner-*
      {{- end }}
      {{- if .Values.addons.gitlab.enabled }}
      - resources:
          namespaces:
          - gitlab
          names:
          - webservice-test-runner-*
      {{- end }}
      {{- if .Values.twistlock.enabled }}
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-defender-ds*
          - volume-upgrade*
      {{- end }}
      {{- if .Values.addons.mimir.enabled }}
      - resources:
          namespaces:
          - mimir
          names:
          - mimir-mimir-smoke-test-*
      {{- end }}

  # Kyverno Beta feature - https://kyverno.io/docs/writing-policies/verify-images/
  require-image-signature:
    enabled: false
    validationFailureAction: Audit

  require-labels:
    enabled: true
    validationFailureAction: Audit
    parameters:
      require:
      - app.kubernetes.io/name
      - app.kubernetes.io/version

  require-istio-on-namespaces:
    enabled: {{ $istioEnabled }}
    exclude:
      any:
      - resources:
          namespaces:
          # Kuberentes control plane does not use Istio
          - kube-node-lease
          - kube-public
          - kube-system
          # No pods in bigbang / default
          - bigbang
          - default
          # Flux is installed prior to Istio
          - flux-system
          # Istio does not inject itself
          - istio-system
          - istio-gateway

  add-default-securitycontext:
    enabled: true
    {{ if $istioEnabled }}
    parameters:
      excludeContainers:
        - istio-init
    {{- end }}
    {{- if or $deployNodeAgent .Values.twistlock.enabled .Values.fluentbit.enabled .Values.neuvector.enabled .Values.alloy.enabled }}
    exclude:
      any:
      - resources:
          namespaces:
          - kube-system
      {{- if $deployNodeAgent }}
      # Velero.  The node agent backup tool requires root group access to see the host's runtime pod directory which is
      # mounted inside velero/node agent pods.
      - resources:
          namespaces:
          - velero
          names:
          - node-agent*
      {{- end }}
      {{- if .Values.twistlock.enabled }}
      # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
      # - read logs from `/var/log` to watch for malicious processes
      # - audit modifications to `/etc/passwd` (watching for suspicious changes)
      # - access the container runtime socket (observing all running containers on a node)
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-console*
          - twistlock-defender-ds*
          - volume-upgrade-job*
      {{- end }}
      # For GitLab runner CI jobs that require root access
      {{- if .Values.addons.gitlabRunner.enabled }}
      - resources:
          namespaces:
          - gitlab-runner
          names:
          - runner-*
      {{- end }}
      {{- if .Values.fluentbit.enabled }}
      # Fluentbit requires access to journalctl as well as /var/log.  This would require modifications
      # to the host operating system, creating a user, adding that user to the  systemd-journal user group
      # and then granting permissions recursively on /var/log.
      - resources:
          namespaces:
          - fluentbit
          names:
          - fluentbit-fluent-bit*
      {{- end }}
      {{- if .Values.neuvector.enabled }}
      # neuvector enforcers run as root to perform real time scanning on the nodes/cluster
      - resources:
          namespaces:
          - neuvector
          names:
          - neuvector-enforcer-pod-*
          - neuvector-controller-pod-*
          - neuvector-cert-upgrader-job-*
      {{- end }}
      {{- if .Values.addons.mattermost.enabled }}
        # Mattermost fails when policy was implemented
      - resources:
          namespaces:
          - mattermost
          - mattermost-operator
          names:
          - mattermost-*
      {{- end }}
      {{- if .Values.alloy.enabled }}
      # Alloy requires access to journalctl as well as /var/log.  This would require modifications
      # to the host operating system, creating a user, adding that user to the systemd-journal user group
      # and then granting permissions recursively on /var/log.
      - resources:
          namespaces:
          - alloy
          names:
          - alloy-alloy-logs*
      {{- end }}
    {{- end }}


  require-non-root-group:
    validationFailureAction: Enforce
    {{ if $istioEnabled }}
    parameters:
      excludeContainers:
        - istio-init
    {{- end }}
    {{- if or $deployNodeAgent .Values.twistlock.enabled .Values.fluentbit.enabled .Values.neuvector.enabled .Values.alloy.enabled }}
    exclude:
      any:
      - resources:
          namespaces:
          - kube-system
      {{ if .Values.istiod.enabled }}
      - resources:
          namespaces:
          - istio-system
          names:
          - istiod*
      {{- end }}
      {{- if $deployNodeAgent }}
      # Velero.  The node agent backup tool requires root group access to see the host's runtime pod directory which is
      # mounted inside velero/node agent pods.
      - resources:
          namespaces:
          - velero
          names:
          - node-agent*
      {{- end }}
      {{- if .Values.twistlock.enabled }}
      # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
      # - read logs from `/var/log` to watch for malicious processes
      # - audit modifications to `/etc/passwd` (watching for suspicious changes)
      # - access the container runtime socket (observing all running containers on a node)
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-defender-ds*
          - volume-upgrade-job*
      {{- end }}
      # For GitLab runner CI jobs that require root access
      {{- if .Values.addons.gitlabRunner.enabled }}
      - resources:
          namespaces:
          - gitlab-runner
          names:
          - runner-*
      {{- end }}
      {{- if .Values.fluentbit.enabled }}
      # Fluentbit requires access to journalctl as well as /var/log.  This would require modifications
      # to the host operating system, creating a user, adding that user to the  systemd-journal user group
      # and then granting permissions recursively on /var/log.
      - resources:
          namespaces:
          - fluentbit
          names:
          - fluentbit-fluent-bit*
      {{- end }}
      {{- if .Values.neuvector.enabled }}
      # neuvector enforcers run as root to perform real time scanning on the nodes/cluster
      - resources:
          namespaces:
          - neuvector
          names:
          - neuvector-enforcer-pod-*
          - neuvector-controller-pod-*
          - neuvector-cert-upgrader-job-*
      {{- end }}
      {{- if .Values.alloy.enabled }}
      # Alloy requires access to journalctl as well as /var/log.  This would require modifications
      # to the host operating system, creating a user, adding that user to the systemd-journal user group
      # and then granting permissions recursively on /var/log.
      - resources:
          namespaces:
          - alloy
          names:
          - alloy-alloy-logs*
      {{- end }}
    {{- end }}

  require-non-root-user:
    validationFailureAction: Enforce
    {{ if $istioEnabled }}
    parameters:
      excludeContainers:
        - istio-init
    {{- end }}
    exclude:
      any:
      - resources:
          namespaces:
          - kube-system
    {{- if or $deployNodeAgent .Values.twistlock.enabled .Values.fluentbit.enabled .Values.kiali.enabled .Values.neuvector.enabled .Values.alloy.enabled }}
      {{- if .Values.kiali.enabled }}
      # Kiali needs exception for operator to deploy Kiali server
      - resources:
          namespaces:
          - kiali
          names:
          - kiali-*
      {{- end }}
      {{- if .Values.neuvector.enabled }}
      # Neuvector needs privileged access for realtime scanning of files from the node / access to the container runtime
      - resources:
          namespaces:
          - neuvector
          names:
          - neuvector*
      {{- end }}
      {{- if $deployNodeAgent }}
      # Velero.  The node agent backup tool requires root user access to the host's runtime pod directory which is
      # mounted inside velero/node agent pods.
      - resources:
          namespaces:
          - velero
          names:
          - node-agent*
      {{- end }}
      # For GitLab runner CI jobs that require root access
      {{- if .Values.addons.gitlabRunner.enabled }}
      - resources:
          namespaces:
          - gitlab-runner
          names:
          - runner-*
      {{- end }}
      {{- if .Values.twistlock.enabled }}
      # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
      # - read logs from `/var/log` to watch for malicious processes
      # - audit modifications to `/etc/passwd` (watching for suspicious changes)
      # - access the container runtime socket (observing all running containers on a node)
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-defender-ds*
          - volume-upgrade-job*
      {{- end }}
      {{- if .Values.fluentbit.enabled }}
      # Fluentbit requires access to journalctl as well as /var/log.  This would require modifications
      # to the host operating system, creating a user, adding that user to the systemd-journal user group
      # and then granting permissions recursively on /var/log.
      - resources:
          namespaces:
          - fluentbit
          names:
          - fluentbit-fluent-bit*
      {{- end }}
      {{- if .Values.alloy.enabled }}
      # Alloy requires access to journalctl as well as /var/log.  This would require modifications
      # to the host operating system, creating a user, adding that user to the systemd-journal user group
      # and then granting permissions recursively on /var/log.
      - resources:
          namespaces:
          - alloy
          names:
          - alloy-alloy-logs*
      {{- end }}
    {{- end }}

  {{- if .Values.twistlock.enabled }}
  restrict-apparmor:
    exclude:
      any:
      # NEEDS FURTHER JUSTIFICATION
      # Twistlock Defenders use an `unconfined` appArmor profile.
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-defender-ds*
  {{- end }}

  restrict-capabilities:
    validationFailureAction: Enforce
    # NEEDS FURTHER JUSTIFICATION
    # Twistlock Defenders require the following capabilities
    # - NET_ADMIN  - Process monitoring and Iptables
    # - NET_RAW    - Iptables (CNNF, runtime DNS, WAAS)  See https://bugzilla.redhat.com/show_bug.cgi?id=1895032
    # - SYS_ADMIN  - filesystem monitoring
    # - SYS_PTRACE - local audit monitoring
    # - SYS_CHROOT - changing mount namespace using setns
    # - MKNOD      - Create special files using mknod, used by docker-less registry scanning
    # - SETFCAP    - Set file capabilties, used by docker-less registry scanning
    # - IPC_LOCK
    # {{- if .Values.twistlock.enabled }}
    # exclude:
    #   any:
    #   - resources:
    #       namespaces:
    #       - twistlock
    #       names:
    #       - twistlock-defender-ds*
    # {{- end }}
    parameters:
      allow:
      # Defaults from https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted
      - NET_BIND_SERVICE
      {{- if $istioEnabled }}
      # Istio requires NET_ADMIN and NET_RAW for sidecar init: https://istio.io/latest/docs/ops/deployment/requirements/#pod-requirements
      # It uses these permissions to setup iptables for network routing
      # Cannot create exclusion since sidecar is injected in most containers, so allow the capabilities globally
      - NET_ADMIN
      - NET_RAW
      {{- end }}
    # Twistlock Defenders run as root to perform real time scanning on the nodes/cluster, including:
    # - read logs from `/var/log` to watch for malicious processes
    # - audit modifications to `/etc/passwd` (watching for suspicious changes)
    # - access the container runtime socket (observing all running containers on a node)
    {{- if or .Values.twistlock.enabled .Values.alloy.enabled }}
    exclude:
      any:
      {{- if .Values.twistlock.enabled }}
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-defender-ds*
      {{- end }}
      {{- if .Values.alloy.enabled }}
      - resources:
          namespaces:
          - alloy
          names:
          - alloy-alloy-metrics*
          - alloy-alloy-receiver*
          - alloy-alloy-logs*
          - alloy-alloy-singleton*
      {{- end }}
    {{- end }}
  restrict-host-path-mount:
    validationFailureAction: Enforce
    {{- if or .Values.fluentbit.enabled .Values.monitoring.enabled .Values.twistlock.enabled .Values.neuvector.enabled .Values.alloy.enabled $deployNodeAgent }}
    exclude:
      any:
      {{- if .Values.fluentbit.enabled }}
      - resources:
          namespaces:
          - fluentbit
          names:
          # Fluent Bit mounts the following hostPaths:
          # - `/var/log`: to tail node logs (e.g. journal) and pod logs
          # - `/var/lib/docker/containers`: to tail container logs
          # - `/etc/machine-id`: to obtain the node's unique machine ID for identifying systemd log folder
          # - `/var/log/flb-storage`: for Fluent Bit's buffering and persistent state
          # Since logs can have sensitive information, it is better to exclude
          # FluentBit from the policy than add the paths as allowable mounts
          - fluentbit-fluent-bit*
      {{- end }}
      {{- if .Values.monitoring.enabled }}
      # Prometheus Node Exporter mounts the following hostPaths:
      # - `/`: monitor disk usage on filesystem mounts using e2fs call
      # - `/proc` and `/sys`: gather node metrics
      # Since mounting the root would expose sensitive information, it is better to
      # exlcude Prometheus Node Exporter than add the paths as allowable mounts
      - resources:
          namespaces:
          - monitoring
          names:
          - monitoring-monitoring-prometheus-node-exporter*
      {{- end }}
      {{- if .Values.twistlock.enabled }}
      # NEEDS FURTHER JUSTIFICATION
      # Twistlock mounts the following hostPaths:
      # - `/dev/log`: writing twistlock logs to syslog socket on node (if enabled)
      # - `/var/lib/twistlock`: data folder reserved for twistlock
      # - `/etc/passwd`: audits changes to passwd file
      # - `/var/run`: communication to docker daemon
      # - `/var/lib/containers`: Container images data from CRI
      # - `/var/run/docker/netns`: Docker's Network Namespace
      # - `/var/log/audit`: Audit logs
      # Because the mounts are dynamically created for defenders at runtime, we cannot
      # anticipate all of the paths it may mount and must exclude it from the policy
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-defender-ds*
      {{- end }}
      {{- if .Values.neuvector.enabled }}
      # Neuvector mounts the following hostPaths:
      # `/var/neuvector`: for Neuvector's buffering and persistent state
      # `/var/run`: communication to docker daemon
      # `/proc`: monitoring of proccesses for malicious activity
      # `/sys/fs/cgroup`: important files the controller wants to monitor for malicious content
      - resources:
          namespaces:
          - neuvector
          names:
          - neuvector-enforcer-pod*
          - neuvector-cert-upgrader-job-*
          - neuvector-controller-pod*
      {{- end }}
      {{- if .Values.alloy.enabled }}
      # Alloy mounts the following hostPaths:
      # - `/var/log`: to tail node logs (e.g. journal) and pod logs
      # - `/var/lib/docker/containers`: to tail container logs
      - resources:
          namespaces:
          - alloy
          names:
          - alloy-alloy-logs*
      {{- end }}
      {{- if $deployNodeAgent }}
      # Velero.  The node agent backup tool requires root user access to the host's runtime pod directory which is
      # mounted inside velero/node agent pods.  Since the host's pod runtime directory may expose sensitive information,
      # it is better to exclude the node agent pods than to add the path as allowable mounts
      - resources:
          namespaces:
          - velero
          names:
          - node-agent*
      {{- end }}
    {{- end }}

  # NOTE: This restricts the ability to have PVCs when using a local path provisioner storage class (i.e. k3d default).
  # To override either disable this policy (not ideal) or add an allowed wildcard matching where local paths are provisioned.
  # See `docs/assets/configs/example/policy-overrides-k3d.yaml` for an example of how to do this for k3d.
  restrict-host-path-mount-pv:
    validationFailureAction: Enforce

  restrict-host-path-write:
    validationFailureAction: Enforce
    {{- if or .Values.neuvector.enabled .Values.twistlock.enabled }}
    exclude:
      any:
      # NEEDS FURTHER JUSTIFICATION
      # Twistlock mounts the following hostPaths as writable:
      # - `/dev/log`: writing twistlock logs to syslog socket on node (if enabled)
      # - `/var/lib/twistlock`: data folder reserved for twistlock
      # - `/run` or `/var/run`: communication to docker daemon and IP tables
      # - `/var/lib/containers`: Container images data from CRI
      # - `/var/log/audit`: Audit logs
      # Because the mounts are dynamically created for defenders at runtime, we cannot
      # anticipate all of the paths it may mount and must exclude it from the policy
      {{- if .Values.twistlock.enabled }}
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-defender-ds*
      {{- end }}
      {{- if .Values.neuvector.enabled }}
      # Neuvector mounts the following hostPaths as writeable:
      # `/var/neuvector`: for Neuvector's buffering and persistent state
      - resources:
          namespaces:
          - neuvector
          names:
          - neuvector-controller-pod*
          - neuvector-enforcer-pod*
      {{- end }}
    {{- end }}
    {{- if .Values.fluentbit.enabled }}
    parameters:
      allow:
      # FluentBit - `/var/log/flb-storage`: fluent bit buffering and persistent state
      - /var/log/flb-storage/
      # FluentBit - `/var/log`
      # NO JUSTIFICATION - Issue opened at https://repo1.dso.mil/big-bang/product/packages/fluentbit/-/issues/31
      # Temporarily added so policy could be enforced
      - /var/log
    {{- end }}

  restrict-image-registries:
    validationFailureAction: Enforce
    parameters:
      allow:
      - registry1.dso.mil
      - registry.dso.mil
    exclude:
      any:
      # istio/gateway sets the deployment image to `auto` by default
      # and does not expose any way for the chart consumer to modify
      # it. The idea is `istiod` will inject the correct image at
      # pod creation based on `istiod`'s proxy config.
      {{- if .Values.istioGateway.enabled }}
      - resources:
          namespaces:
          - istio-gateway
          names:
          - '*-ingressgateway'
          - '*-egressgateway'
      {{- end }}

  {{- if or .Values.fluentbit.enabled .Values.twistlock.enabled .Values.alloy.enabled }}
  restrict-selinux-type:
    exclude:
      any:
      {{- if .Values.fluentbit.enabled }}
      - resources:
          namespaces:
          - fluentbit
          names:
          # NEEDS FURTHER JUSTIFICATION
          # FluentBit needs selinux option type spc_t
          - fluentbit-fluent-bit*
      {{- end }}
      {{- if .Values.twistlock.enabled }}
      # NEEDS FURTHER JUSTIFICATION
      # Twistlock Defenders need selinux option type spc_t
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-defender-ds*
      {{- end }}
      {{- if .Values.alloy.enabled }}
      - resources:
          namespaces:
          - alloy
          names:
          # Alloy requires SELinux option type 'spc_t' for privileged host volume mounting on SELinux enabled systems
          # Alloy mounts the following hostPaths:
          # - `/var/log`: to tail node logs (e.g. journal) and pod logs
          # - `/var/lib/docker/containers`: to tail container logs
          - alloy-alloy-logs-*
      {{- end }}
  {{- end }}

  {{- if $deployNodeAgent }}
  restrict-user-id:
    exclude:
      any:
      {{- if $deployNodeAgent }}
      # Velero.  The node agent backup tool requires root user access to the host's runtime pod directory which is
      # mounted inside velero/node agent pods.
      - resources:
          namespaces:
          - velero
          names:
          - node-agent*
      {{- end }}
  {{- end }}

  {{- if or .Values.fluentbit.enabled .Values.monitoring.enabled .Values.twistlock.enabled .Values.neuvector.enabled .Values.alloy.enabled $deployNodeAgent }}
  restrict-volume-types:
    exclude:
      any:
      {{- if or .Values.fluentbit.enabled }}
      - resources:
          namespaces:
          - fluentbit
          names:
          # Fluent bit containers requires HostPath volumes, to tail node and container logs.  It is also used for buffering
          # https://docs.fluentbit.io/manual/pipeline/filters/kubernetes#workflow-of-tail-+-kubernetes-filter
          - fluentbit-fluent-bit*
          {{- end }}
      {{- if .Values.monitoring.enabled }}
      # Prometheus node exporter requires a HostPath volume to monitor host metrics in /proc and /sys
      - resources:
          namespaces:
          - monitoring
          names:
          - monitoring-monitoring-prometheus-node-exporter*
      {{- end }}
      {{- if .Values.twistlock.enabled }}
      # Twistlock requires access to node logs, syslog, and docker daemon for defense monitoring
      # https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/audit/logging.html
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-defender-ds*
      {{- end }}
      {{- if .Values.neuvector.enabled }}
      # Neuvector requires HostPath volume types
        # Neuvector mounts the following hostPaths:
        # `/var/neuvector`: (as writable) for Neuvector's buffering and persistent state
        # `/var/run`: communication to docker daemon
        # `/proc`: monitoring of proccesses for malicious activity
        # `/sys/fs/cgroup`: important files the controller wants to monitor for malicious content
      # https://github.com/neuvector/neuvector-helm/blob/master/charts/core/templates/enforcer-daemonset.yaml#L108
      - resources:
          namespaces:
          - neuvector
          names:
          - neuvector-enforcer-pod*
          - neuvector-controller-pod*
      {{- end }}
      {{- if .Values.alloy.enabled }}
      # Alloy mounts the following hostPaths:
      # - `/var/log`: to tail node logs (e.g. journal) and pod logs
      # - `/var/lib/docker/containers`: to tail container logs
      - resources:
          namespaces:
          - alloy
          names:
          - alloy-alloy-logs*
      {{- end }}
      {{- if $deployNodeAgent }}
      # Velero.  The node agent backup tool requires root user access to the host's runtime pod directory which is
      # mounted inside velero/node agent pods.
      - resources:
          namespaces:
          - velero
          names:
          - node-agent*
      {{- end }}
  {{- end }}

  update-automountserviceaccounttokens-default:
    enabled: true
    namespaces:
      - istio-system
      - twistlock
      - argocd
      - logging
      - velero
      - minio
      - minio-operator
      - kyverno-reporter
      - kyverno
      - velero
      - neuvector
      - kiali
      - harbor
      - authservice
      - anchore
      - fortify
      - vault
      - fluentbit
      - eck-operator
      - nexus-repository-manager
      - thanos
      - mattermost
      - mattermost-operator
      - bigbang
      - flux-system
      - keycloak
      - monitoring
      - gitlab
      - gitlab-runner
      - headlamp

  update-automountserviceaccounttokens:
    enabled: true
    namespaces:
      - namespace: istio-system
        pods:
          allow:
          - istiod-*
          - passthrough-ingressgateway-*
          - public-ingressgateway-*
      - namespace: twistlock
        pods:
          allow:
          # For twistlock the gluon wait-job needs to query namespaces and check defenders are up
          - twistlock-twistlock-wait-job-*
          # twistlock-init pods require get/list/patch/etc to several resources.
          # More details in twistlock/chart/templates/init/clusterrole.yaml
          - twistlock-init-*
          # twistlock-volume-upgrade-job requires patch/get/list/update to deployments and get/list to pods
          # More details in twistlock/chart/templates/init/volume-upgrade-role.yaml
          - twistlock-volume-upgrade-job
          # Twistlock Defender enforces various policies that may involve the K8s cluster itself
          # Enforcing said policies requires access to the API to get/list resources
          - twistlock-defender-ds-*
          # bb-twistlock-upgrade-job requires patch/get/list/update/etc to deployments daemonsets pv's and pvc
          # More details in twistlock/chart/templates/bigbang/upgrade-job.yaml
          - bb-twistlock-twistlock-upgrade-job-*
          # For the gluon script test job to access the K8s API
          - twistlock-twistlock-script-test
      - namespace: logging
        pods:
          allow:
          - logging-loki-minio-*
          - logging-ek-wait-job-*
          - logging-loki-script-test
          deny:
          - logging-ek-es-data*
          - logging-ek-es-master*
          - logging-ek-kb*
          - logging-ek-metrics*
      - namespace: minio-operator
        pods:
          allow:
          # console pods require access to several API resources
          # More details in minio-operator/chart/templates/console-clusterrole.yaml
          - console-*
          # operator pods require access to several API resources
          # More details in minio-operator/chart/templates/operator-clusterrole.yaml
          - minio-operator-*
          # tenantPatchJob requires get/list/patch on tenants (minio CRD)
          # More details in minio-operator/chart/templates/bigbang/tenant-patch-job.yaml
          - bb-minio-operator-minio-operator-tenant-patch
      - namespace: minio
        pods:
          allow:
          # tenant pods require get/list/watch on secrets/tenants (CRD), and create/delete/get on services
          # More details in role named minio-minio-minio-instance-role
          - minio-minio-minio-instance-*
          - minio-minio-wait-job-*
          - minio-minio-script-test
      - namespace: kyverno
        pods:
          allow:
          - kyverno-reports-controller-*
          - kyverno-admission-controller-*
          - kyverno-cleanup-controller-*
          - kyverno-cleanup-admission-reports-*
          - kyverno-admission-controller-*
          - kyverno-background-controller-*
          - kyverno-admission-controller-*
          - kyverno-cleanup-cluster-admission-reports-*
          - kyverno-cleanup-cluster-ephemeral-reports-*
          - kyverno-cleanup-update-requests-*
          - kyverno-clean-reports-*
      - namespace: velero
        pods:
          allow:
          - velero-cleanup-crds-*
          - velero-velero-*
          - node-agent-*
          - velero-label-namespace-*
          - velero-script-test
          - velero-backup-restore-test
      - namespace: neuvector
        pods:
          allow:
          - neuvector-manager-pod-*
          - neuvector-scanner-pod-*
          - neuvector-cert-upgrader-job-*
          - neuvector-controller-pod-*
          - neuvector-enforcer-pod-*
          - neuvector-updater-pod-*
          - neuvector-prometheus-exporter-pod-*
          - neuvector-registry-adapter-pod-*
      - namespace: kiali
        pods:
          allow:
          - kiali-*
      - namespace: argocd
        pods:
          allow:
          # application-controller pods interact with secrets, configmaps, events, and Argo CRDs
          # More details in argocd/chart/templates/argocd-application-controller/role.yaml
          - argocd-argocd-application-controller-*
          # dex pods interact with secrets and configmaps
          # More details in argocd/chart/templates/dex/role.yaml
          - argocd-argocd-dex-server-*
          # argocd-upgrade-job interacts with CRDs
          # More details in argocd/chart/templates/bigbang/upgrade-job.yaml
          - argocd-upgrade-job-*
          # argocd server pods interact with secrets, configmaps, events, and CRDs
          # More details in argocd/chart/templates/argocd-server/role.yaml
          - argocd-argocd-server-*
          # repo server pods require access to the K8s API if using RBAC
          # Ref: https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/rbac.md
          - argocd-argocd-repo-server-*
          # The applicationSet controller pods interact with many API resources, including CRDs
          # More details in argocd/chart/templates/argocd-applicationset/role.yaml
          - argocd-argocd-applicationset-controller-*
          # notifications controller pods interact with secrets, configmaps, and CRDs
          # More details in argocd/chart/templates/argocd-notifications/role.yaml
          # Additionally (this wildcard covers both)-
          # notifications bot pods interact with secrets, configmaps, and CRDs
          # More details in argocd/chart/templates/argocd-notifications/bots/slack/role.yaml
          - argocd-argocd-notifications-controller-*
          # needed to allow gluon 0.9.0 to execute test.sh script
          - argocd-argocd-script-test
      - namespace: harbor
        pods:
          allow:
          - harbor-script-test
        # Omitting the serviceAccount and Pods section forces the policy to apply to
        # all of the serviceAccount and Pods in the namespace
      - namespace: authservice
        pods:
          allow:
          - authservice-authservice-redis-bb-*
          - authservice-haproxy-sso-*
      - namespace: monitoring
        pods:
          allow:
          - monitoring-grafana*
          - monitoring-monitoring-kube-admission-create-*
          - monitoring-monitoring-kube-admission-patch-*
          - monitoring-monitoring-kube-state-metrics*
          - monitoring-monitoring-kube-operator*
          - prometheus-monitoring-monitoring-kube-prometheus*
      - namespace: alloy
        pods:
          allow:
          - alloy-*
      - namespace: mimir
        pods:
          allow:
          - mimir-mimir-rollout-operator-*
          - mimir-mimir-minio*
          - mimir-mimir-script-test*
      - namespace: anchore
        pods:
          allow:
          - anchore-ui-redis-*
          - redis-clean-upgrade-*
      - namespace: fortify
        # Omitting the serviceAccount and pods section forces the policy to apply to
        # all of the serviceAccounts and pods in the namespace
      - namespace: vault
        pods:
          allow:
          - vault-vault-*
          - vault-vault-agent-injector-*
          - vault-vault-job-init-*
      - namespace: fluentbit
        pods:
          allow:
          - fluentbit-fluent-bit-*
      - namespace: eck-operator
        pods:
          allow:
          - elastic-operator-*
      - namespace: nexus-repository-manager
        pods:
          allow:
          - nexus-repository-manager-*
      - namespace: thanos
        pods:
          allow:
          - thanos-minio-*
          deny:
          - thanos-query-frontend-*
          - thanos-storegateway*
          - thanos-query*
      - namespace: mattermost
        pods:
          allow:
          - default-minio-bucket-creation-*
          - mattermost-minio-*
          - mattermost-wait-job-*
      - namespace: mattermost-operator
        pods:
          allow:
          - mattermost-operator-*
      - namespace: keycloak
        pods:
          allow:
          - keycloak-*
      - namespace: gitlab
        pods:
          allow:
          - gitlab-shared-secrets*
          - gitlab-script-test
      - namespace: gitlab-runner
        pods:
          allow:
          - gitlab-runner-*
      - namespace: headlamp
        pods:
          allow:
          - headlamp-*

istio:
  enabled: {{ $istioEnabled }}

{{- end }}

############################################################
# Define istio-gateway here needed for helm unittest
############################################################

{{- define "bigbang.defaults.istio-gateway" -}}
gateways:
  public:
    gateway:
      servers:
      - hosts:
        - '*.{{ .Values.domain }}'
        port:
          name: http
          number: 8080
          protocol: HTTP
        tls:
          httpsRedirect: true
      - hosts:
        - '*.{{ .Values.domain }}'
        port:
          name: https
          number: 8443
          protocol: HTTPS
        tls:
          credentialName: public-cert
          mode: SIMPLE

    upstream:
      serviceAccount:
        create: true
        name: public-ingressgateway-ingressgateway-service-account

      imagePullPolicy: {{ .Values.imagePullPolicy }}

      imagePullSecrets:
        - name: private-registry

      labels:
        istio: ingressgateway

  passthrough:
    gateway:
      servers:
      - hosts:
        - '*.{{ .Values.domain }}'
        port:
          name: http
          number: 8080
          protocol: HTTP
        tls:
          httpsRedirect: true
      - hosts:
        - '*.{{ .Values.domain }}'
        port:
          name: https
          number: 8443
          protocol: HTTPS
        tls:
          mode: PASSTHROUGH

    upstream:
      serviceAccount:
        create: true
        name: passthrough-ingressgateway-ingressgateway-service-account

      imagePullPolicy: {{ .Values.imagePullPolicy }}

      imagePullSecrets:
        - name: private-registry

      labels:
        istio: ingressgateway
{{- end }}

{{- if and .Values.istiod.enabled .Values.istioGateway.enabled }}
{{- include "bigbang.istio-gateway-secrets" . }}
{{- end }}

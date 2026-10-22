{{- /*
Kyverno PolicyExceptions for Istio ingress/egress gateways.
Aggregated into the kyverno-policies chart's additionalPolicyExceptions value.
*/ -}}
{{- define "bigbang.kyvernoPolicyExceptions.istioGateway" -}}
{{- $packages := default (dict) .Values.packages -}}
{{- $istioGateway := default (dict) (get $packages "istioGateway") -}}
{{- if eq (include "packageEnabled" (dict "root" . "name" "istioGateway")) "true" }}
# istio/gateway sets the deployment image to `auto` (injected by istiod at pod
# creation) and does not expose a way to override it, so the gateway pods cannot
# satisfy the image tag / registry policies.
istio-gateway-image:
  spec:
    policyRefs:
      - name: disallow-image-tags
        kind: ValidatingPolicy
      - name: restrict-image-registries
        kind: ValidatingPolicy
    matchConditions:
      - name: istio-gateways
        expression: >-
          (object.metadata.namespace == 'istio-gateway' && (
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).contains('-ingressgateway') ||
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).contains('-egressgateway')
          ))
{{- /* Istio ingress gateways may intentionally create type: NodePort Services. */}}
{{- $nodePortIngressGateways := list }}
{{- range $name, $values := (dig "values" "gateways" dict $istioGateway) }}
{{- if eq $values.type "NodePort" }}
{{- $nodePortIngressGateways = append $nodePortIngressGateways $name }}
{{- end }}
{{- end }}
{{- range $name, $values := (dig "values" "gateways" dict $istioGateway) }}
{{- if eq (dig "k8s" "service" "type" "LoadBalancer" $values) "NodePort" }}
{{- $nodePortIngressGateways = append $nodePortIngressGateways $name }}
{{- end }}
{{- end }}
{{- $gatewayServiceNames := list }}
{{- if and (eq (include "packageEnabled" (dict "root" . "name" "istiod")) "true") (eq (include "packageEnabled" (dict "root" . "name" "istioGateway")) "true") }}
{{- range $name, $gw := include "enabledGateways" $ | fromYaml }}
{{- $gatewayServiceNames = append $gatewayServiceNames $gw.serviceName }}
{{- end }}
{{- end }}
{{- $clauses := list }}
{{- if $nodePortIngressGateways }}
{{- $clauses = append $clauses (printf "(object.metadata.namespace == 'istio-system' && object.metadata.name in %s)" (toJson $nodePortIngressGateways)) }}
{{- end }}
{{- if $gatewayServiceNames }}
{{- $clauses = append $clauses (printf "(object.metadata.namespace == 'istio-gateway' && object.metadata.name in %s)" (toJson $gatewayServiceNames)) }}
{{- end }}
{{- if $clauses }}
istio-gateway-disallow-nodeport-services:
  spec:
    policyRefs:
      - name: disallow-nodeport-services
        kind: ValidatingPolicy
    matchConditions:
      - name: istio-nodeport-gateways
        expression: {{ join " || " $clauses | quote }}
{{- end }}
{{- end }}
{{- end -}}

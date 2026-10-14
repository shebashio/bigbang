{{/* Mirrors the ServiceMonitor component body from k8s-monitoring 4.5.3, retaining user scrape and selector settings. */}}
{{- define "bigbang.alloy.serviceMonitorComponent" -}}
{{- $upstream := .Values.alloy.values.upstream | default dict }}
{{- $global := mergeOverwrite (dict "scrapeInterval" "60s" "scrapeTimeout" "10s" "scrapeClassicHistograms" false "scrapeNativeHistograms" false "convertClassicHistogramsToNhcb" false "nativeHistogramBucketLimit" 0 "nativeHistogramMinBucketFactor" 0) (deepCopy ($upstream.global | default dict)) }}
{{- $sm := dig "prometheusOperatorObjects" "serviceMonitors" dict $upstream }}
{{- $metricAllowList := dig "metricsTuning" "includeMetrics" list $sm }}
{{- $metricDenyList := dig "metricsTuning" "excludeMetrics" list $sm }}
allow_arbitrary_file_access = true
  kubernetes_role = "endpointslice"
{{- if $sm.namespaces }}
  namespaces = {{ $sm.namespaces | toJson }}
{{- end }}
{{- if or $sm.labelSelectors $sm.labelExpressions }}
  selector {
  {{- if $sm.labelSelectors }}
    match_labels = {
    {{- range $key, $value := $sm.labelSelectors }}
      {{ $key | quote }} = {{ $value | quote }},
    {{- end }}
    }
  {{- end }}
  {{- range $expression := $sm.labelExpressions }}
    match_expression {
      key = {{ $expression.key | quote }}
      operator = {{ $expression.operator | quote }}
      {{ if $expression.values }}values = {{ $expression.values | toJson }}{{ end }}
    }
  {{- end }}
  }
{{- end }}
  clustering {
    enabled = true
  }
  scrape {
    default_scrape_interval = {{ $sm.scrapeInterval | default $global.scrapeInterval | quote }}
    default_scrape_timeout = {{ $sm.scrapeTimeout | default $global.scrapeTimeout | quote }}
    scrape_classic_histograms = {{ $global.scrapeClassicHistograms }}
    scrape_native_histograms = {{ $global.scrapeNativeHistograms }}
    convert_classic_histograms_to_nhcb = {{ $global.convertClassicHistogramsToNhcb }}
    native_histogram_bucket_limit = {{ $global.nativeHistogramBucketLimit | int }}
    native_histogram_min_bucket_factor = {{ $global.nativeHistogramMinBucketFactor | float64 }}
  }

{{- with $sm.excludeNamespaces }}
  rule {
    source_labels = ["job"]
    regex = "serviceMonitor/({{ . | join "|" }})/.*"
    action = "drop"
  }
{{- end }}
{{- if $sm.extraDiscoveryRules }}
{{ $sm.extraDiscoveryRules | indent 2 }}
{{- end }}
{{- if or $metricAllowList $metricDenyList $sm.extraMetricProcessingRules }}
  forward_to = [prometheus.relabel.servicemonitors.receiver]
{{- else }}
  forward_to = argument.metrics_destinations.value
{{- end }}
{{- end }}

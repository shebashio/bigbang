# Scrape Annotated Application Metrics

Big Bang's monitoring package can discover Prometheus metrics from annotated Services or Pods when a matching scrape job is configured. Prefer a package-owned `ServiceMonitor` or `PodMonitor` when one is available; annotation discovery is useful for applications that do not provide those resources.

## Prerequisites

- The Big Bang monitoring package is enabled.
- The application exposes metrics in Prometheus format.
- The scrape path, port, and protocol are known.
- Network policies allow Prometheus to reach the target.
- Mesh authorization and TLS settings permit the scrape. An HTTP scrape configuration alone does not provide the certificates needed to reach a sidecar endpoint protected by strict mTLS.

## Enable Annotation Discovery

For Big Bang 4.0, configure discovery through `packages.monitoring.values.upstream`. The former `globalServiceEndpointMetrics` and `globalPodEndpointMetrics` switches are not accepted by the current umbrella schema, including beneath `packages.monitoring`.

The following **umbrella values** add two namespace-scoped jobs. Replace `my-application` with the application namespace and retain only the discovery job you need. Each job selects a port named `metrics`, so an application with multiple ports is not scraped repeatedly.

This list replaces an existing `additionalScrapeConfigs` list at the same upstream path. Include any jobs you already require, including an umbrella-generated Vault scrape job when applicable, in the resulting list.

```yaml
packages:
  monitoring:
    values:
      upstream:
        prometheus:
          prometheusSpec:
            additionalScrapeConfigs:
              - job_name: annotated-services
                kubernetes_sd_configs:
                  - role: endpointslice
                    namespaces:
                      names: [my-application]
                relabel_configs:
                  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
                    action: keep
                    regex: "true"
                  - source_labels: [__meta_kubernetes_endpointslice_port_name]
                    action: keep
                    regex: metrics
                  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
                    target_label: __scheme__
                    regex: (https?)
                  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
                    target_label: __metrics_path__
                    regex: (.+)
                  - source_labels: [__meta_kubernetes_namespace]
                    target_label: namespace
                  - source_labels: [__meta_kubernetes_service_name]
                    target_label: service
              - job_name: annotated-pods
                kubernetes_sd_configs:
                  - role: pod
                    namespaces:
                      names: [my-application]
                relabel_configs:
                  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
                    action: keep
                    regex: "true"
                  - source_labels: [__meta_kubernetes_pod_container_port_name]
                    action: keep
                    regex: metrics
                  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scheme]
                    target_label: __scheme__
                    regex: (https?)
                  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
                    target_label: __metrics_path__
                    regex: (.+)
                  - source_labels: [__meta_kubernetes_namespace]
                    target_label: namespace
                  - source_labels: [__meta_kubernetes_pod_name]
                    target_label: pod
```

These jobs use HTTP unless the scheme annotation specifies HTTPS. HTTPS targets also need appropriate certificate trust and, when required, client certificates in the scrape job; do not disable certificate verification to make a target appear healthy. See [Prometheus scrape configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config).

For the complete passthrough configuration, see the [upstream values for kube-prometheus-stack 91.4.1](https://github.com/prometheus-community/helm-charts/blob/kube-prometheus-stack-91.4.1/charts/kube-prometheus-stack/values.yaml), used by monitoring 91.4.1-bb.2. Consult the upstream version bundled with your deployed package when upgrading.

## Annotate a Service

This **Kubernetes Service** selects existing application Pods whose container exposes a port named `metrics`. Substitute the actual labels, numeric Service port, and path:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-application
  namespace: my-application
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/scheme: "http"
    prometheus.io/path: "/metrics"
spec:
  ports:
    - name: metrics
      port: 8080
      targetPort: metrics
  selector:
    app.kubernetes.io/name: my-application
```

The Service job discovers the backing EndpointSlice port. These examples use port names for selection and do not consume `prometheus.io/port`; set the actual port on the Service and workload instead.

## Annotate a Pod

For Pod discovery, merge this **Deployment fragment** into the application's existing Pod template. Keep the application's other container settings and replace `my-application` with its container name:

```yaml
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/scheme: "http"
        prometheus.io/path: "/metrics"
    spec:
      containers:
        - name: my-application
          ports:
            - name: metrics
              containerPort: 8080
```

Do not annotate both the Service and its Pods when both jobs are enabled, or combine annotation discovery with a `ServiceMonitor`/`PodMonitor` for the same endpoint, unless duplicate ingestion is intentional.

## Verify the Target

After Flux reconciles the configuration:

1. Open the Prometheus Targets page.
2. Find the target under `annotated-services` or `annotated-pods`.
3. If it is absent, inspect Prometheus service discovery and confirm the annotations and selectors.
4. If it is present but down, verify the port, path, protocol, TLS settings, and applicable network policies.
5. Confirm that the target is `UP` and the application's expected metrics are available.

Inspect discovery resources without changing them:

```shell
kubectl get services,pods -n my-application
kubectl get endpointslices -n my-application -l kubernetes.io/service-name=my-application
```

For package-specific dashboards, alerts, and `ServiceMonitor` settings, use the documentation for that package and the [monitoring package](../packages/core/monitoring.md).

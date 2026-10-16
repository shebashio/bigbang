# Scrape Annotated Application Metrics

Big Bang's monitoring package can discover Prometheus metrics from annotated Services or Pods. Prefer a package-owned `ServiceMonitor` or `PodMonitor` when one is available; annotation discovery is useful for applications that do not provide those resources.

## Prerequisites

- The Big Bang monitoring package is enabled.
- The application exposes metrics in Prometheus format, or a suitable exporter provides them.
- The scrape path, port, and protocol are known.
- Network policies allow Prometheus to reach the target.

## Enable Annotation Discovery

Enable one or both discovery jobs in the Big Bang values supplied by the environment:

```yaml
monitoring:
  globalServiceEndpointMetrics:
    enabled: true
  globalPodEndpointMetrics:
    enabled: true
```

These values render the `kubernetes-service-endpoints` and `kubernetes-pods` scrape jobs respectively. They are disabled by default. Enable only the jobs you need.

## Annotate a Service or Pod

### Service

Add annotations to the application's Service. Substitute the actual metrics port and path:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-application
  namespace: my-application
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
spec:
  ports:
    - name: metrics
      port: 8080
      targetPort: metrics
  selector:
    app.kubernetes.io/name: my-application
```

### Pod

For Pod discovery, add annotations to the workload's Pod template:

```yaml
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
```

This example shows the relevant portion of a Deployment manifest.

Do not enable annotation discovery and a `ServiceMonitor` or `PodMonitor` for the same endpoint unless duplicate ingestion is intentional.

## Verify the Target

After Flux reconciles the configuration:

1. Open the Prometheus Targets page.
2. Find the target under `kubernetes-service-endpoints` or `kubernetes-pods`.
3. If it is absent, inspect Prometheus Service Discovery and confirm the discovery job, annotations, and selectors.
4. If it is present but down, verify the port, path, protocol, TLS settings, and applicable network policies.
5. Confirm the target is `UP` and the expected metrics are available.

For more information about Prometheus discovery and scrape configuration, see the [Prometheus configuration documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/).

For package-specific dashboards, alerts, and `ServiceMonitor` settings, see the [Monitoring package documentation](../packages/core/monitoring.md).
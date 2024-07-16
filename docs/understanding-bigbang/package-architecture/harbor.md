### Harbor

```mermaid
graph LR
  subgraph "Harbor"
    harborpods("Harbor Pods")
  end

  subgraph "Ingress"
    ig(Ingress Gateway) --> harborpods("Harbor Pods")
  end

  subgraph "External Databases"
    harborpods("Harbor Pods") --> database1[(PostgreSQL DB)]
    harborpods("Harbor Pods") --> database2[(Redis DB)]
  end

  subgraph "Object Storage (S3/Swift)"
    harborpods("Harbor Pods") --> bucket[(Harbor Bucket)]
  end

  subgraph "Image Scanner"
    harborpods("Harbor Pods") --> Trivy("Trivy")
  end

  subgraph "Logging"
    harborpods("Harbor Pods") --> fluent(Fluentbit) --> logging-ek-es-http
    logging-ek-es-http{{Elastic Service<br />logging-ek-es-http}} --> elastic[(Elastic Storage)]
  end

  subgraph "Monitoring"
    svcmonitor("Service Monitor") --> harborpods("Harbor Pods")
    Prometheus --> svcmonitor("Service Monitor")
  end


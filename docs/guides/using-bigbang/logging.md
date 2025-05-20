# Big Bang Logging Stacks

These instructions detail how choose enable logging application stack for your Big Bang deployment.

As of Big Bang 3.0, there are two primary logging stacks offered: ALG (Default), and EFK.

The ALG stack is the Grafana family consisting of: Alloy, Loki, Grafana
- Alloy is a multi-purpose OpenTelemetry collector agent, which is used to collect logs and forward them to Loki. 
- Loki is the main service, responsible for storing logs and processing queries.
- Grafana is a front-end web interface for querying and displaying the logs.

The EFK stack is an open-source choice for the Kubernetes log aggregation and analysis and is comprised of the following:
- Elasticsearch is a distributed and scalable search engine commonly used to sift through large volumes of log data.
- Fluentbit is a log shipper. It is an open source log collection agent which support multiple data sources and output formats.
- Kibana is a User Interface (UI) tool for querying, data visualization and dashboards.

The ALG stack comes enabled with Big Bang by default.

## Switching Logging Stacks

Switching different logging stacks is as easy as swapping enable/disable values for desired applications.

```yaml
# Big Bang values.yaml
# Example: Enabling EFK logging stack instead of ALG

elasticsearchKibana:
  # -- Toggle deployment of Logging (Elastic/Kibana).
  enabled: true

eckOperator:
  # -- Toggle deployment of ECK Operator.
  enabled: true

fluentbit:
  # -- Toggle deployment of Fluent-Bit.
  enabled: true

alloy:
  # -- Toggle deployment of grafana alloy
  enabled: false

loki:
  # -- Toggle deployment of Loki.
  enabled: false

grafana:
  # -- Toggle deployment of Grafana
  enabled: false
```

## Fluentbit with Loki

There may also be use cases where teams may want to run Fluentbit with Loki, often for lighter resources or plugin support.

Big Bang supports this use case, and can be enabled simply by enabling the Fluentbit and Loki packages in values.yaml

```yaml
# Big Bang values.yaml
# Example: Enabling Fluentbit with Loki

fluentbit:
  # -- Toggle deployment of Fluent-Bit.
  enabled: true

loki:
  # -- Toggle deployment of Loki.
  enabled: true

grafana:
  # -- Toggle deployment of Grafana
  enabled: true
```


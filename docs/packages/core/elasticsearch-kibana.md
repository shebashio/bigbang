# Elasticsearch-Kibana

## Overview

This page covers the umbrella's Elasticsearch/Kibana and ECK Operator orchestration and license routing. Workload storage, Kibana access, SSO, networking, and operational guidance belong in the [package migration draft guide](https://repo1.dso.mil/big-bang/product/packages/elasticsearch-kibana/-/blob/76bea319822232afab2c22505e83a66e9ca2d03d/docs/overview.md).

The [ECK Operator package](https://repo1.dso.mil/big-bang/product/packages/eck-operator) owns the controller, CRD lifecycle, and operator integration; see its [draft guide](https://repo1.dso.mil/big-bang/product/packages/eck-operator/-/blob/64260d2473a1d320f4959bcaeb2884bdd5bfa9b4/docs/overview.md). Workload custom resources and operator lifecycle are configured and versioned in separate packages.

## Big Bang Touch Points

With `packageConfiguration.version: v1`, use `packages.elasticsearchKibana` for the workload and `packages.eckOperator` for the operator. Legacy root-level configuration remains supported; see [Package Management](../../concepts/package-management.md).

- Enabling Elasticsearch/Kibana also renders the ECK Operator release, even when the operator's explicit enablement is false. ECK Operator can also be enabled independently.
- By default, the `ek` HelmRelease targets namespace `logging` and depends on `eck-operator`; the operator release targets namespace `eck-operator`.
- The workload package renders ECK `Elasticsearch` and `Kibana` custom resources. The operator reconciles them; operator and workload configuration are not interchangeable.
- Logging-stack selection and collector enablement remain umbrella concerns; see [Big Bang Logging Stacks](../../concepts/logging.md).

## Licensing

The umbrella accepts license inputs under `packages.elasticsearchKibana.license` when using the v1 configuration contract, or `elasticsearchKibana.license` for legacy configuration. It forwards `trial` and `keyJSON` into the ECK Operator package's generated `license` values, not into the Elasticsearch/Kibana workload chart. The operator package manages the corresponding license resources in its release namespace.

Treat license JSON as sensitive deployment data: use protected, encrypted deployment inputs rather than committing license material to documentation or plaintext values. Setting `trial: true` requests the operator package's trial resource; trial eligibility, terms, licensed features, and expiry behavior remain defined by Elastic. See [Elastic's ECK license management](https://www.elastic.co/docs/deploy-manage/license/manage-your-license-in-eck) and [subscriptions](https://www.elastic.co/subscriptions) rather than a copied feature matrix.

# GitLab

## Overview

[Gitlab](https://about.gitlab.com/) is an open-source with premium offering, self-hostable Git repository, build system and container registry.

Big Bang's implementation uses the [Gitlab Helm Chart](https://docs.gitlab.com/charts/) to provide custom resources and manage the application.

A more detail view of Big Bang's implementation of Gitlab can be found in the [package docs](https://repo1.dso.mil/big-bang/product/packages/gitlab/-/tree/main/chart/doc).

## Big Bang Touch Points

### UI

The Gitlab UI is the primary way of interacting with Gitlab. The UI is accessible via a web application on the cluster at the DNS name "gitlab" (e.g. gitlab.bigbang.com). The UI provides access to all Gitlab features.

### Logging

Gitlab has a logging mechanism built in that logs all relevant events in a json format. More detailed information can be found in their [logging docs](https://docs.gitlab.com/ee/administration/logs.html).

### Monitoring

GitLab metrics integration is enabled when the Big Bang monitoring package is enabled. Grafana is deployed separately by `packages.grafana`. For example, in **umbrella values**:

```yaml
packages:
  monitoring:
    enabled: true
```

### Health Checks

Gitlab provides built in health checks.

```shell
GET /-/health
```

Example request

```shell
curl "https://gitlab.example.com/-/health"
```

Gitlab also provides a separate liveness and readiness probes.

```shell
GET /-/readiness
GET /-/readiness?all=1
```

Example request

```shell
curl "https://gitlab.example.com/-/readiness"
```

```shell
GET /-/liveness
```

Example request

```shell
curl "https://gitlab.example.com/-/liveness"
```

More information can be found in the gitlab documentation [here](https://docs.gitlab.com/administration/monitoring/health_check/).

## High Availability

GitLab deployed on a Kubernetes(K8S) cluster can achieve “self healing”. In other words, if a container goes down, K8S replaces it with a new one. K8S can also provide rolling upgrades. However, a K8S deployment by itself does not provide full high availablity(HA). Refer to the upstream [Gitlab HA reference achitectures](https://docs.gitlab.com/ee/administration/reference_architectures/). The Gitlab helm chart provides the ability to set replica counts for some of the services as shown in the BigBang values override example below. 

Note that the gitaly service requires a significant and non-trivial amout of configuration to acheive HA. Gitaly provides high-level RPC access to Git repositories. It is used by GitLab to read and write Git data. A Gitaly cluster must be created on Praefect nodes. The Big Bang Product Team has not yet tested use of a Gitaly cluster and will not be able to provide support. If you require Gitaly HA refer to the upstream [Gitaly Cluster documentation](https://docs.gitlab.com/ee/administration/gitaly/praefect.html) and leverage a support contact with Gitlab. For small to medium deployments, increasing Gitaly resources as shown below does not make Gitaly highly available.

The following **umbrella values** pass component overrides to the GitLab upstream chart. Provision the external services described in [GitLab production considerations](../../configuration/production-considerations/gitlab.md) first, and size replicas and resources for the environment:
```yaml
packages:
  gitlab:
    values:
      upstream:
        gitlab:
          webservice:
            minReplicas: 3
            maxReplicas: 3
          gitlab-shell:
            minReplicas: 3
            maxReplicas: 3
          sidekiq:
            minReplicas: 3
            maxReplicas: 3
          gitaly:
            resources:
              limits:
                cpu: 2
                memory: 4G
              requests:
                cpu: 2
                memory: 4G
        registry:
          hpa:
            minReplicas: 3
            maxReplicas: 3
```

## Single Sign On (SSO)

Gitlab can be integrated with Keycloak for single sign on. Full documentation can be found in the package docs [here](https://repo1.dso.mil/big-bang/product/packages/gitlab/-/blob/main/docs/keycloak.md).

## Licensing

GitLab is built on an open core model. GitLab Community Edition is open source, with an MIT Expat license. GitLab Enterprise Edition is built on top of Community Edition.

GitLab Enterprise Edition uses the same core, but adds additional features and functionality on top of that. These additional features are under a proprietary license that makes the code published source-available.

The pinned upstream GitLab chart defaults to Enterprise Edition (`ee`), and the
Big Bang package pins EE images. The edition is separate from license
entitlement: installing EE does not by itself grant paid features. Consult the
[upstream edition guidance](https://docs.gitlab.com/charts/installation/deployment/#deploy-the-community-edition)
and the package's pinned images before changing editions.

More information about GitLab licensing can be found [here](https://about.gitlab.com/install/ce-or-ee/) for the information page and [here](https://gitlab.com/gitlab-org/gitlab/-/blob/master/LICENSE) for the actual license.

## Storage

### Database Storage

GitLab requires an independently provisioned PostgreSQL database. GitLab 19 and
chart 10 no longer bundle PostgreSQL, Redis, or MinIO. See the
[external-service prerequisites and umbrella values example](../../configuration/production-considerations/gitlab.md#configure-required-external-services).
Existing installations must migrate their bundled services before upgrading; follow
the [GitLab 19 upgrade notes](https://repo1.dso.mil/big-bang/product/packages/gitlab/-/blob/main/docs/gitlab-19-upgrade.md).

### File Storage

GitLab requires independently provisioned object storage and buckets. The
[external-service example](../../configuration/production-considerations/gitlab.md#configure-required-external-services)
shows S3-compatible configuration and explains endpoint, credential, and bucket
requirements. Big Bang does not create the buckets.

## Dependencies

Pass GitLab upstream chart overrides through `packages.gitlab.values.upstream` in umbrella values. See the [upstream chart 10.5.1 values](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/v10.5.1/values.yaml) for the complete configuration.

```yaml
packages:
  gitlab:
    values:
      upstream: {}
```

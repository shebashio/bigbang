# MinIO Package Boundaries

The [MinIO tenant draft guide](https://repo1.dso.mil/big-bang/product/packages/minio/-/blob/1f78da20e5b20ad7fcd2d0dcf33ea895d990102b/docs/overview.md) covers tenant configuration, storage, access, networking, and operations.

MinIO Operator controller and custom-resource lifecycle guidance belongs to the separately versioned MinIO Operator package. Umbrella orchestration remains here until that migration is complete.

## Big Bang Touchpoints

### UI

The MinIO Console UI is the primary way of interacting with a MinIO tenant. The UI is accessible via a web browser. The UI provides access to all of a tenants features. This includes access to features very similar to what you would see in AWS S3, setting up buckets, controlling access, etc. 


### Logging

MinIO supports configuring audit logs through both the MinIO Console UI and the MinIO `mc` command line tool. For Kubernetes environments, the MinIO Operator automatically configures the Console with a LogSearch integration for visual inspection of collected audit logs.

By default logs are also shipped to Elastic via Fluentbit for advanced searching/indexing. The filter `kubernetes.namespace_name` set to your MinIO tenant namespace can provide easy viewing of MinIO only logs.

### Monitoring

Monitoring is provided via a Prometheus capable endpoint. MinIO also provides a Grafana dashboard for use in viewing metrics. Monitoring in the Big Bang config can be enabled using the following format.

```yaml
monitoring:
  enabled: false
  namespace: monitoring
```

### Health Checks

MinIO server exposes three un-authenticated, healthcheck endpoints [liveness probe](https://github.com/minio/minio/blob/master/docs/metrics/healthcheck/README.md#liveness-probe) and a [cluster probe](https://github.com/minio/minio/blob/master/docs/metrics/healthcheck/README.md#cluster-probe) at /minio/health/live and /minio/health/cluster respectively.


## High Availability

The default is to run in high availability. The default number of servers is 4, but can be changed by changing the values in the base Big Bang cofiguration.

```yaml
addons:
  minio:
    values:
      tenants:
        pools:
        - servers: 8
          volumesPerServer: 4
          size: 256Mi
          resources:
            requests:
              cpu: 250m
              memory: 2Gi
            limits:
              cpu: 250m
              memory: 2Gi
          securityContext:
            runAsUser: 1001
            runAsGroup: 1001
            fsGroup: 1001
```

Note that due to the list used for the pool value you may need to include resources, requests, and securityContext so that you don't run into issues.

You can also set things like the number of volumes per server and affinity rules for the MinIO tenant.

## Single Sign On (SSO)

No current SSO is available via Keycloak.

## Configuring access to Minio without SSO

Initial access to the MinIO server is via the accessKey and secretKey values in the top level values file.

```yaml
addons:
  minio:
    accesskey: "myaccesskey"
    secretkey: "mysecretkey"
```


## Licensing

MinIO has recently updated its license to the GNU AFFERO General Public License. This requires that any product containing usage of their product to also release their code as open source.

License can be found [here](https://github.com/minio/minio/blob/master/LICENSE)

## Storage

### File Storage

MinIO is dependent on a default storage class being configured. This is a core prereq for Big Bang itself so this should already in place when starting up the Big Bang framework. The MinIO process will need to create PersistentVolumes and PersistentVolumeClaims for its storage. The requirement for these are that they have a volumeBindingMode: WaitForFirstConsumer. The MinIO operator should take care of creating these at tenant start up.


## Dependencies

As mentioned above, MinIO needs to have access to create the needed PersistentVolumes needed for its storage. This can be EBSs in an AWS environment or a similar storage solution in place.

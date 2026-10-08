# Troubleshoot Performance

Use this guide when a Big Bang deployment is healthy but workloads are slow, resource constrained, or experiencing increased latency.

If Flux resources, HelmReleases, or workloads are not healthy, start with [Troubleshooting](index.md) instead.

## Identify the Bottleneck

Start by determining whether the problem affects a single workload, multiple workloads, or the entire cluster.

For a quick check of current CPU and memory usage:

```shell
kubectl top nodes
kubectl top pods -A
```

To inspect a specific workload:

```shell
kubectl top pod <pod-name> -n <namespace> --containers
kubectl describe pod <pod-name> -n <namespace>
```

`kubectl top` requires Metrics Server and provides a recent view of CPU and memory usage. Use the monitoring tools configured for your environment to investigate historical trends and correlate performance with other metrics.

See [Monitoring](../monitoring.md) for Big Bang observability guidance.

## Diagnose by Symptom

Use metrics, workload status, and events to identify the bottleneck before changing resource or application configuration.

| Symptom | Investigate |
| --- | --- |
| High CPU usage or slow response under load | CPU usage, requests and limits, and application-specific metrics |
| CPU throttling | CPU limits and workload demand |
| High memory usage or `OOMKilled` containers | Memory usage, requests and limits, and application memory behavior |
| Pods remain `Pending` | Pod events, resource requests, node capacity, and scheduling constraints |
| Node resource pressure | Node resource usage, allocatable resources, and affected workloads |
| Slow storage or I/O | Storage configuration, volume behavior, and the underlying storage platform |
| Slow service-to-service communication | Network path, Istio metrics, and application latency |
| Kubernetes resources are healthy but the application is slow | Application metrics, logs, dependencies, and package documentation |

For Kubernetes resource behavior, see [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).

For pod scheduling or runtime problems, see [Debug Running Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/).

## Check CPU and Memory Configuration

Compare actual resource usage with the workload's configured requests and limits:

```shell
kubectl get pod <pod-name> -n <namespace> \
  -o jsonpath='{.spec.containers[*].resources}'
```

CPU and memory requests are used when Kubernetes schedules workloads. CPU limits can throttle CPU usage, while exceeding memory limits can result in a container being terminated for out-of-memory conditions.

Do not change requests or limits solely because a workload is slow. Use observed resource usage and workload requirements to determine whether resource configuration is contributing to the problem.

See [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) for details about requests and limits.

## Check Node Capacity and Scheduling

If the issue affects multiple workloads or pods cannot obtain the resources they request, inspect node usage and capacity:

```shell
kubectl top nodes
kubectl describe node <node-name>
```

Review pod events for scheduling failures:

```shell
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

Kubernetes schedules pods based on their resource requests and available node capacity. Pod events can identify insufficient resources and other scheduling constraints.

For detailed scheduling troubleshooting, see [Debug Running Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/).

## Check Network and Service-Mesh Performance

For increased request latency or slow service-to-service communication, determine whether the delay is isolated to an application or affects multiple services.

If the affected traffic uses Istio, review mesh and application metrics to identify where latency is occurring. Istio performance can vary based on traffic characteristics, proxy resources, configuration, and enabled telemetry.

See:

- [Istio standard metrics](https://istio.io/latest/docs/reference/config/metrics/)
- [Istio performance and scalability](https://istio.io/latest/docs/ops/deployment/performance-and-scalability/)

If the problem is connectivity rather than performance, see [Package or workload troubleshooting](index.md#packages).

## Verify Performance Changes

After changing resource or application configuration:

1. Test the change under a representative workload.
2. Compare the same metrics used to identify the original bottleneck.
3. Compare results against an established performance baseline, when available.
4. Confirm that the change improves the original symptom without introducing resource pressure or other regressions.
5. Validate the change in a non-production environment before applying it to production when possible.

Avoid treating increased resource limits, additional replicas, or infrastructure capacity as default fixes. The appropriate change depends on the identified bottleneck.

## Escalate the Issue

If the bottleneck cannot be identified or resolved, collect:

- Big Bang and affected package versions
- Affected workloads and namespaces
- When the performance issue occurs
- CPU and memory usage
- Relevant resource requests and limits
- Node resource usage, if applicable
- Application or service latency metrics
- Relevant events and logs
- Recent configuration, package, or infrastructure changes

Review diagnostic output before sharing it because metrics, logs, and resource information can contain environment-specific or sensitive information.
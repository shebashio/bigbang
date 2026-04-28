# Ambient Mode on Big Bang is now in Beta

Big Bang 3.23 introduces support for **Istio Ambient Mesh** as an opt-in (beta) feature. By default, Ambient is **disabled**, allowing existing deployments to continue operating without disruption. Users can explicitly enable Ambient to begin evaluating its benefits and tradeoffs in controlled environments.

This post provides a high-level overview of what Ambient brings, how it impacts networking, and what changes were made in Big Bang to support it.

## Why Ambient?

Ambient Mesh provides significant advantages over the sidecar approach by drastically reducing resource overhead. As the number of workloads increases, these benefits become more pronounced since each pod no longer requires its own dedicated proxy. 

Instead, each node runs a shared Layer 4 proxy (ztunnel) that applications across the cluster can opt into. This also means that pods no longer need to be restarted when Istio is updated to ensure they are using the most up-to-date image.

In addition, Ambient Mesh significantly reduces the complexity of onboarding new applications. This not only makes it easier and quicker to bring new packages into Big Bang, but also simplifies onboarding for mission applications into the mesh.

## Opt-In Ambient (Beta)

Ambient Mesh is available in Big Bang 3.23, but is not enabled by default. When enabled, it should be treated as beta, and production use should be carefully evaluated based on your environment's needs.

Ambient can be enabled by setting the `istio.ambient.enabled` flag to `true` in your values configuration file, which enables it globally for all Big Bang applications.

For more information on configuration and what is enabled behind the scenes, refer to the [Enabling Ambient Mode documentation](https://docs-bigbang.dso.mil/latest/docs/configuration/ambient/?h=ambient/#enabling-ambient-mode).

## Changes to the Network Stack

Ambient introduces a fundamental change in how traffic flows:

* **No per-pod sidecar proxies** → reduced resource overhead
* **Node-level L4 processing (ztunnel)** → handles mTLS and basic policy enforcement
* **Optional L7 processing (waypoints)** → used selectively for advanced use cases

One of the most significant changes from a networking perspective is that workloads now communicate over TCP port 15008 (HBONE) when using the tunnel. This requirement is automatically handled by the bb-common integration, which allows this port when Ambient is enabled.

From a security perspective, once traffic is allowed over the tunnel, it can reach any port on the destination workload. To address this, Big Bang automatically enables Layer 4 Authorization Policies to ensure environments remain properly segmented and secure.

For a deeper dive into the architecture, please check out [this link](https://istio.io/latest/docs/ambient/architecture/).

## Current Implementation

Ambient Mesh today is primarily focused on Layer 4. However, Layer 7 capabilities are still available through **waypoint proxies**, which are deployed only where needed.

In Big Bang, this is particularly relevant for applications that rely on **Authservice** for authentication which should continue to function in the same way (using the Authservice label):

* Prometheus
* AlertManager
* Thanos

Additional waypoint proxies can be manually deployed using [Istio's configuration documentation](https://istio.io/latest/docs/ambient/usage/waypoint/), but there is currently no built-in support for templating them via the Big Bang chart.

## Basic Troubleshooting

Since the `istio-proxy` containers no longer exist, troubleshooting shifts to inspecting ztunnel logs.

The following command retrieves the last 500 log entries for all ztunnel pods:

`kubectl logs -l app.kubernetes.io/name=ztunnel -n istio-system --tail 500`

You can combine this with `grep` to filter for specific workloads or errors.

Below is an example of an error that indicates a problem with a missing or misconfigured network policy:

```
error	access	connection complete	src.addr=10.42.1.22:36146 src.workload="kiali-5f4f9bd98c-jdb59" src.namespace="kiali" src.identity="spiffe://cluster.local/ns/kiali/sa/kiali-service-account" dst.addr=10.42.1.17:15008 dst.hbone_addr=10.42.1.17:9090 dst.service="monitoring-monitoring-kube-prometheus.monitoring.svc.cluster.local" dst.workload="prometheus-monitoring-monitoring-kube-prometheus-0" dst.namespace="monitoring" dst.identity="spiffe://cluster.local/ns/monitoring/sa/monitoring-monitoring-kube-prometheus" direction="outbound" bytes_sent=0 bytes_recv=0 duration="0ms" error="io error: Connection refused (os error 111)"
```

> **Note**: As mentioned earlier, TCP port 15008 is the primary port used when in Ambient mode so close attention should be paid to the `dst.addr` when troubleshooting network policy related issues. 

Another example shows what it may look like if you have a missing or misconfigured authorization policy:

```
error	access	connection complete	src.addr=10.42.1.22:56558 src.workload="kiali-5f4f9bd98c-jdb59" src.namespace="kiali" src.identity="spiffe://cluster.local/ns/kiali/sa/kiali-service-account" dst.addr=10.42.2.10:15008 dst.hbone_addr=10.42.2.10:3200 dst.service="tempo-tempo.tempo.svc.cluster.local" dst.workload="tempo-tempo-0" dst.namespace="tempo" dst.identity="spiffe://cluster.local/ns/tempo/sa/tempo-tempo" direction="inbound" bytes_sent=0 bytes_recv=0 duration="0ms" error="connection closed due to policy rejection: allow policies exist, but none allowed"
```

You can also use the [istioctl](https://istio.io/latest/docs/ops/diagnostic-tools/istioctl/) utility to analyze the entire environment to look for any issues that stick out by executing the following command:

`istioctl analyze -A`

For a more in-depth troubleshooting resource please refer to the [following link](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient).

## Summary

Big Bang 3.23 introduces Ambient Mesh as a **beta, opt-in feature** that:

* **Simplifies the data plane** by removing per-pod proxies
* Shifts enforcement toward **L4 Authorization Policies + Network Policies**
* Supports **selective L7 processing** for authentication for packages that leverage Authservice

Please stay tuned for further updates as our Ambient implementation progresses.
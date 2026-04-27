# Ambient Mode on Big Bang is now in Beta!!!

Big Bang 3.23 introduces support for **Istio Ambient Mesh** as an opt-in (beta) feature. By default, Ambient is **disabled**, allowing existing deployments to continue operating without disruption. Users can explicitly enable Ambient to begin evaluating its benefits and tradeoffs in controlled environments.

This post provides a high-level overview of what Ambient brings, how it impacts networking, and what changes were made in Big Bang to support it.

## Opt-In Ambient (Beta)

Ambient Mesh is available in Big Bang 3.23 but is not enabled by default. When enabled, it should be treated as beta, and production use should be carefully evaluated based on your environment’s needs.

Ambient can be enabled by setting the `istio.ambient.enabled` flag to `true` in your values configuration file, which enables it globally for all Big Bang applications.

For more information on configuration and what is enabled behind the scenes, refer to the [Enabling Ambient Mode documentation](https://docs-bigbang.dso.mil/latest/docs/configuration/ambient/?h=ambient/#enabling-ambient-mode).

## Changes to the Network Stack

Ambient introduces a fundamental change in how traffic flows:

* **No per-pod sidecar proxies** → reduced resource overhead
* **Node-level L4 processing (ztunnel)** → handles mTLS and basic policy enforcement
* **Optional L7 processing (waypoints)** → used selectively for advanced use cases

One of the most significant changes from a networking perspective is that workloads now communicate over TCP port 15008 (HBONE) when using the tunnel. This requirement is automatically handled by the bb-common integration, which allows this port when Ambient is enabled.

Another important change is that once traffic is allowed over the tunnel, it effectively gains access to all ports on the destination workload. To address this, Big Bang automatically enables Layer 4 Authorization Policies to ensure environments remain properly segmented and secure.

For a deeper dive into the architecture, please check out [this link](https://istio.io/latest/docs/ambient/architecture/).

## Current Implementation

Ambient Mesh today is primarily focused on Layer 4. However, Layer 7 capabilities are still available through **waypoint proxies**, which are deployed only where needed.

In Big Bang, this is particularly relevant for applications that rely on **Authservice** for authentication which should continue to function in the same way (using the Authservice label):

* Prometheus
* AlertManager
* Thanos

Additional waypoint proxies can be manually deployed, but there is currently no built-in support for templating them via the Big Bang chart.

## Basic Troubleshooting

Since the `istio-proxy` containers no longer exist, troubleshooting shifts to inspecting ztunnel logs.

The following command retrieves the last 500 log entries for all ztunnel pods:

`kubectl logs -l app.kubernetes.io/name=ztunnel -n istio-system --tail 500`

You can combine this with `grep` to filter for specific workloads or errors.

Common errors include:

* "Connection refused" - Typically indicates a missing or misconfigured Network Policy.
* "RBAC: access denied" - Typically indicates a missing or misconfigured Layer 4 Authorization Policy.

You can also use the [istioctl](https://istio.io/latest/docs/ops/diagnostic-tools/istioctl/) utility to analyze the entire environment to look for any issues that stick out by executing the following command:

`istioctl analyze -A`

For a more in-depth troubleshooting resource please refer to the [following link](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient).

## Summary

Big Bang 3.23 introduces Ambient Mesh as a **beta, opt-in feature** that:

* **Simplifies the data plane** by removing per-pod proxies
* Shifts enforcement toward **L4 Authorization Policies + Network Policies**
* Supports **selective L7 processing** for authentication for packages that leverage Authservice

Please stay tuned for further updates as our Ambient implementation progresses.
# Migrating a Big Bang Environment from Sidecar Mode to Ambient Mode

> [!WARNING]
> Ambient mode is **beta** in Big Bang: not fully integrated and **not recommended for
> production** until it is promoted to stable (after Big Bang 4.0). Treat this as a staged,
> reversible migration and validate in a lower environment first.

[[_TOC_]]

## Overview

Migrate a live Big Bang environment from Istio **sidecar mode** (`istio-injection:
enabled`, per-pod Envoy) to **ambient mode** (node-level `ztunnel` for L4/mTLS, optional
waypoints for L7).

Standing up a **new** ambient environment instead? See
[Configuring Istio Ambient Mode in Big Bang](./ambient.md).

### Related documentation

- [Configuring Istio Ambient Mode in Big Bang](./ambient.md)
- [Running Mission Applications in Ambient](./ambient-mission-apps.md)
- [ztunnel Package](../packages/core/ztunnel.md) / [Gateway API Package](../packages/core/gateway-api.md)
- Upstream: [Migrating to Ambient Mode](https://istio.io/latest/docs/ambient/install/)

## What Changes

For the broad sidecar-vs-ambient concepts (ztunnel, waypoints, HBONE, the
`istio.io/dataplane-mode` label, default-deny authz), see Istio's
[Ambient overview](https://istio.io/latest/docs/ambient/overview/). Below is only what is
**Big Bang-specific**.

Setting the single switch `istio.ambient.enabled: true` automatically:

1. Deploys the required infra packages: **ztunnel**, **istio-cni**, **gateway-api**.
2. Sets `PILOT_ENABLE_AMBIENT: "true"` on istiod.
3. Swaps `istio-injection` for `istio.io/dataplane-mode: ambient` on Big Bang-managed
   package namespaces and disables sidecar injection.
4. Enables default authorization policies and injects the HBONE port (15008) into
   generated network policies.

## Migration Procedure

> [!NOTE]
> Test end-to-end in non-production first. Ambient and sidecar workloads interoperate, so
> you can migrate in stages rather than atomically.

### Step 1: Enable ambient mode

Add the switch to your **existing** Big Bang values (an addition, not a replacement):

```yaml
istio:
  ambient:
    enabled: true
```

The flag also turns on `ztunnel`, `istioCNI`, and `gatewayAPI`; override their values only
if your platform requires it:

```yaml
istioCNI:
  values:
    cni:
      cniBinDir: /opt/cni/bin       # customize for your platform
      cniConfDir: /etc/cni/net.d    # customize for your platform
```

### Step 2: Reconcile and roll out the infrastructure

```bash
flux reconcile source git bigbang -n bigbang
flux reconcile hr bigbang -n bigbang
```

Wait for the ambient infrastructure to become healthy **in dependency order** before
touching applications: istiod picks up `PILOT_ENABLE_AMBIENT` → istio-cni Ready on every
node → ztunnel Ready on every node → gateway-api CRDs installed.

```bash
kubectl -n istio-system rollout status ds/ztunnel
kubectl -n kube-system  rollout status ds/istio-cni-node
kubectl get hr -A        # all HelmReleases Ready
```

> [!IMPORTANT]
> **Most pods roll into ambient automatically.** Enabling ambient changes the
> `bigbang.dev/istioDataplane` annotation Big Bang stamps onto nearly every package, so the
> pod-template hash changes and Flux recreates those pods sidecar-free. Two exceptions:
> (1) workloads without the annotation (e.g. the neuvector **enforcer** DaemonSet) keep
> their sidecar until you restart them; (2) clustered/quorum packages roll all at once and
> can stall (see [Known Issues](#known-issues-and-gotchas)). Once settled, run the
> [Validation](#validation) checks and restart any stragglers.

### Step 3: Migrate mission apps and non-integrated charts

For each workload not managed by Big Bang's `packages` key / `bb-common`, apply the
ambient namespace label, HBONE network policies, kubelet health-probe policy, and
authorization policies from
[Running Mission Applications in Ambient](./ambient-mission-apps.md), then restart them.

## Handling Special Cases

### Clustered workloads that break under STRICT mTLS during the mixed window

Workloads that cluster by **direct pod IP** (headless Services / StatefulSets: Consul,
raft, gossip, Elasticsearch, Redis-cluster, MinIO, Vault) can lose member-to-member
connectivity **while a namespace is half sidecar, half ambient** under STRICT mTLS.

**Why:** a sidecar pod dialing a bare pod IP uses Envoy's `PassthroughCluster`: plaintext,
no HBONE tunnel, no mTLS identity. Two ztunnel layers reject it: (1) namespace
`PeerAuthentication: STRICT` drops non-mTLS inbound; (2) the default `allow-all-in-ns`
policy matches on peer identity, which passthrough lacks, so it hits default-deny. The tell
in the ztunnel log is a denied connection with a populated `src.workload` but **empty
`src.identity`**. Only `sidecar → ambient` (by pod IP) breaks; `ambient ↔ ambient` carries
identity and passes STRICT.

**Bridge.** Relax both layers through the package's `values` so bb-common owns the objects:
set `istio.mtls.mode: PERMISSIVE` and add an allow-all custom authz policy (the default
allow-in-namespace matches on identity, which passthrough lacks). For neuvector:

```yaml
# TEMP: sidecar -> ambient migration only. Remove this whole block once every
# neuvector pod is ambient, to restore full STRICT enforcement.
neuvector:
  values:
    istio:
      mtls:
        mode: PERMISSIVE
      authorizationPolicies:
        custom:
          - name: neuvector-migration-allow-all
            spec:
              action: ALLOW
              rules:
                - {}
```

`rules: [{}]` matches any source/port, blunt but reliable. Apply the same shape to any
other clustered package.

**Follow-up (required).** Once every pod in the package is ambient, remove the block:
dropping `istio.mtls.mode` reverts to the default (**STRICT**) and dropping the custom
policy restores default-deny; the HelmRelease prunes both on reconcile. Don't leave
`PERMISSIVE` in place, it disables mTLS enforcement for the package.

> [!NOTE]
> - `portLevelMtls` is **ignored by ztunnel**: use workload- or namespace-level `PERMISSIVE`.
> - A `DENY` policy always beats `ALLOW`; confirm the package has none.

Best of all, **close the mixed window fast**: roll all members of a clustered workload to
ambient together rather than leaving sub-components behind.

### Workloads that need Authservice

ztunnel is L4 only, so L7 SSO enforcement (Authservice OIDC ext_authz) moves from the
sidecar to a **waypoint**. Authservice is currently the only supported waypoint use in Big
Bang, and it is automatic: enabling authservice on a route in ambient mode auto-creates the
shared `authservice-waypoint` Gateway and binds enforcement to the target Service. See:

- [authservice Ambient Mode](https://repo1.dso.mil/big-bang/product/packages/authservice/-/blob/main/docs/AMBIENT.md):
  L7 JWT/authz enforcement and the `waypoint.enabled` toggle (ingress-gateway enforcement
  without a waypoint).
- bb-common Istio: [Waypoint Gateway](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/istio/README.md#waypoint-gateway)
  and [Authservice](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/istio/README.md#authservice):
  the auto-created Gateway, per-route binding, and the `istio.io/ingress-use-waypoint:
  "true"` label for north-south (ingress) traffic.

### `hostNetwork` workloads

hostNetwork pods cannot be enrolled (ztunnel loops `inpod::statemanager retrying workload`
and its readiness probe returns HTTP 500).

**Twistlock is automatic:** with ambient enabled, the twistlock package sets
`istio.io/dataplane-mode: none` on the Defender pods (its `twistlock-defender.labels`
helper), opting them out while the rest of the namespace stays enrolled.

For **other**, unmanaged hostNetwork workloads, opt the pods out yourself with a **pod**
label:

```yaml
istio.io/dataplane-mode: none
```

### Keeping a package or namespace in sidecar mode temporarily

A workload can stay in sidecar mode while the rest is ambient: label its namespace
`istio-injection: enabled` instead of the ambient label. Treat this as **temporary**
(sidecar is deprecated after 4.0). For a Big Bang package, override the namespace label:

```yaml
packages:
  <pkg>:
    namespace:
      labels:
        istio.io/dataplane-mode: none   # or istio-injection: enabled
```

## Validation

1. **All HelmReleases are Ready.** Everything deploys via HelmReleases, so Flux is the
   fastest health signal. Anything stuck `Reconciling`/`Failed` or looping
   upgrade→rollback needs attention (see [Known Issues](#known-issues-and-gotchas)):

   ```bash
   kubectl get hr -A            # STATUS column should read "Ready" for every release
   flux get helmreleases -A     # or, with the Flux CLI, READY=True / MESSAGE=Release reconciliation succeeded
   ```

2. **Ambient infra healthy on every node** (note the split namespaces: `ztunnel` in
   `istio-system`, `istio-cni` and Gateway API in `kube-system`):

   ```bash
   kubectl -n istio-system rollout status ds/ztunnel
   kubectl -n kube-system  rollout status ds/istio-cni-node
   kubectl get hr -A | grep -E 'ztunnel|istio-cni|gateway-api'   # all Ready
   ```

3. **No unexpected sidecars.** Native sidecars put `istio-proxy` in `initContainers`
   (so a sidecar pod shows `2/2` while `.spec.containers` length is 1). Check both lists
   and exclude ztunnel (its container is also named `istio-proxy`):

   ```bash
   kubectl get pods -A -o json \
     | yq -r '.items[]
              | select(((.spec.initContainers // []) | map(.name) | contains(["istio-proxy"]))
                       or (.spec.containers | map(.name) | contains(["istio-proxy"])))
              | select(.metadata.labels.app != "ztunnel")
              | .metadata.namespace + "/" + .metadata.name'
   ```

   The only results should be workloads intentionally kept in sidecar mode, plus the istio
   ingress gateways.

4. **Workloads enrolled in ambient:** `istioctl ztunnel-config workloads`, enrolled
   workloads show a ztunnel/HBONE protocol; opted-out and hostNetwork ones should not
   appear captured.

5. **mTLS / connectivity works**: exercise ingress, service-to-service calls, Prometheus
   scraping, and SSO UIs. Breakage-when-tunneled usually means a missing `15008` in a
   hand-written NetworkPolicy or a missing authorization policy.

6. **ztunnel logs clean**: no repeating `retrying workload` (indicates an un-opted-out
   hostNetwork pod):

   ```bash
   kubectl logs -n istio-system ds/ztunnel | grep -i "retrying workload"
   ```

## Known Issues and Gotchas

> Items marked _(observed)_ were reproduced by enabling `istio.ambient.enabled` in place
> on a default k3d dev deployment.

- **Prometheus loses the sidecar metrics endpoint (15020)** _(observed)_. Sidecar
  injection sets `prometheus.io/port: "15020"` for the Envoy merged-metrics endpoint; in
  ambient nothing listens there, so those scrapes fail (`Connection refused`). Repoint
  affected ServiceMonitors at the app's own metrics port; Istio L7 metrics now come from
  ztunnel/waypoints.

- **Clustered/quorum workloads can stall the rollout** _(observed)_. As a package's pods
  re-form a cluster during the roll, two generations coexist and block convergence; Helm
  times out and **Flux rolls back, recreating the old generation and repeating the
  conflict**. Seen with **neuvector** (Consul `-bootstrap-expect` mismatch, `:18500/ready`
  stuck 503; the prometheus-exporter crashlooped `SSL: UNEXPECTED_EOF_WHILE_READING` until
  controllers recovered) and **loki** (`logging-loki-backend` overran the timeout). It
  self-resolves slowly (~35 min for neuvector). Fix, the **suspend-nudge**: `flux suspend hr
  <pkg>`, let the pods finish rolling to the ambient template (delete lagging old sidecar
  pods), then `flux resume hr <pkg> && flux reconcile hr <pkg> --force`. Since the
  annotation rolls these packages the moment ambient is enabled, validate quorum readiness
  one package at a time. Distinct from the STRICT-mTLS denial in
  [Handling Special Cases](#clustered-workloads-that-break-under-strict-mtls-during-the-mixed-window).

- **Transient wave of not-ready HelmReleases** _(observed)_. ztunnel, istio-cni, and
  gateway-api install fresh at flip time and the deploy-time `kubectl wait ... --timeout`
  can lapse while they settle. Most recover; re-check HR status a few minutes later before
  treating a timeout as a hard failure.

- **hostNetwork pods** break ztunnel enrollment; always opt them out first (see
  [Handling Special Cases](#handling-special-cases)).

- **Hand-written NetworkPolicies** omitting TCP **15008** silently drop tunneled traffic.
  See [Ambient and Kubernetes Network Policy](https://istio.io/latest/docs/ambient/usage/networkpolicy/).

- **Default-deny authorization**: traffic that "just worked" under sidecar can be denied
  until an allow policy exists. Start every namespace with allow-within-namespace.

- **Health/readiness probes** need a kubelet network policy in ambient-captured namespaces.

- **Auto-roll coverage is not total.** The annotation only rolls packages that use Big
  Bang's `istioAnnotation` helper; workloads without it (e.g. the neuvector **enforcer**
  DaemonSet) keep their sidecar until restarted manually. Mixed state is safe, but "flag
  enabled" ≠ fully migrated; verify with [Validation](#validation) and restart stragglers.

- **Detecting leftover sidecars requires checking `initContainers`** _(observed)_: native
  sidecars show `2/2` while `.spec.containers` length is 1. A check on `.spec.containers`
  alone misses every sidecar. ztunnel's own container is also named `istio-proxy`.

- **Beta status**: not for production until ambient is stable for Big Bang 4.0.

## References

- [Configuring Istio Ambient Mode in Big Bang](./ambient.md)
- [Running Mission Applications in Ambient](./ambient-mission-apps.md)
- [ztunnel Package](../packages/core/ztunnel.md) / [Gateway API Package](../packages/core/gateway-api.md)
- [Istio Ambient Overview](https://istio.io/latest/docs/ambient/overview/) /
  [Migrating to Ambient](https://istio.io/latest/docs/ambient/install/) /
  [Ambient and Kubernetes Network Policy](https://istio.io/latest/docs/ambient/usage/networkpolicy/)

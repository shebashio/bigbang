# PRD: Port Kyverno Inline Exclusions to PolicyException Objects

| Field | Value |
|---|---|
| **Status** | Draft |
| **Target completion** | October 2026 (before ClusterPolicy `exclude` deprecation) |
| **Owner** | TBD |
| **Stakeholders** | Big Bang maintainers, kyverno-policies subchart maintainers, package teams |

---

## 1. Problem statement

Big Bang enforces security policy across every workload in the cluster using Kyverno `ClusterPolicy` objects. When an addon genuinely needs elevated privileges — a log collector mounting `/var/log`, a runtime scanner running privileged — we carve out a targeted exclusion so the policy stays enforced everywhere else.

Today those exclusions live as inline `exclude.any[]` blocks inside the kyverno-policies Helm values template (`chart/templates/kyverno-policies/values.yaml`). Each block is gated behind the relevant addon's `.enabled` flag and rendered at template time. This works, but it has a shelf life: **Kyverno's upstream roadmap deprecates inline `exclude` on ClusterPolicy in favor of the `PolicyException` CRD.** Once that deprecation lands, every inline exclude becomes dead code.

Big Bang is currently on Kyverno chart `3.7.0-bb.1` (kyverno-policies `3.3.4-bb.19`), where `kyverno.io/v2` `PolicyException` is fully stable. The machinery to render PolicyException objects already exists in the kyverno-policies subchart via `.additionalPolicyExceptions`. We need to migrate before the deprecation window closes.

**The goal:** replace every inline `exclude` block with an equivalent `PolicyException` object, delivered through the existing subchart plumbing, without disrupting any running cluster during the transition.

---

## 2. Current state

### How inline exclusions work

All policy exclusion logic lives in `chart/templates/kyverno-policies/values.yaml`, which defines two named templates:

- `bigbang.defaults.kyverno-policies` — the BB-managed defaults with all conditional exclusions
- `bigbang.overlays.kyverno-policies` — a merge engine that concatenates user overrides onto those defaults

Each policy section conditionally renders `exclude.any[]` entries based on addon toggles:

```yaml
# Example: current inline exclusion pattern
policies:
  disallow-host-namespaces:
    exclude:
      any:
      {{- if .Values.neuvector.enabled }}
      - resources:
          namespaces:
          - neuvector
          names:
          - neuvector-enforcer-pod*
      {{- end }}
      {{- if .Values.twistlock.enabled }}
      - resources:
          namespaces:
          - twistlock
          names:
          - twistlock-defender-ds*
      {{- end }}
```

This pattern repeats across 21 policies and 80 exclusion entries (72 addon-gated, ~8 static) spanning 20 addons. The merge engine in the overlays template handles concatenation of `exclude.any[]`, `parameters.allow[]`, `parameters.disallow[]`, and other list-type fields.

### What's working

- The exclusions are correct and well-tested in production.
- The addon-gated conditional rendering is clean.
- The merge engine handles user overrides gracefully.

### What's not sustainable

- Inline `exclude` is on the Kyverno deprecation path.
- Every exclusion is baked into the umbrella chart template, meaning package teams can't own their own exceptions.
- The template file is already 1300+ lines of interlocking conditionals.
- No audit trail — when an exclusion fires, there's no Kubernetes object to inspect.

---

## 3. Target state

Each inline `exclude` block becomes a `PolicyException` object rendered by the kyverno-policies subchart. The umbrella chart passes these through `kyvernoPolicies.values.additionalPolicyExceptions`.

### Concrete example

Here's what the `neuvector` `disallow-host-namespaces` exclusion looks like as a PolicyException:

```yaml
# In chart/templates/kyverno-policies/values.yaml (new pattern)
kyvernoPolicies:
  values:
    additionalPolicyExceptions:
      neuvector-disallow-host-namespaces:
        enabled: {{ .Values.neuvector.enabled }}
        kind: PolicyException
        namespace: "kyverno"
        annotations:
          policies.kyverno.io/title: NeuVector host namespace access
          policies.kyverno.io/description: >-
            NeuVector enforcer pods require host namespace access
            for network traffic inspection.
        spec:
          exceptions:
          - policyName: disallow-host-namespaces
            ruleNames:
            - "*"
          match:
            any:
            - resources:
                kinds:
                - Pod
                namespaces:
                - neuvector
                names:
                - neuvector-enforcer-pod*
```

### Key schema notes

- **`PolicyException` is namespaced** but can exempt resources in any namespace — there is no correlation between the namespace where the exception lives and the namespaces it targets. We deploy all BB-managed exceptions to the `kyverno` namespace.
- **`enablePolicyException` and `exceptionNamespace` are required** (Kyverno 1.13+, CVE-2024-48921). PolicyExceptions are disabled by default. The Kyverno deployment must set `enablePolicyException: true` and `exceptionNamespace: kyverno` to restrict exception creation to the `kyverno` namespace. This prevents unprivileged namespace users from creating their own bypass exceptions. BB's kyverno package values must wire these flags.
- **`ruleNames: ["*"]`** exempts all rules in a policy. Autogen rules (e.g., `autogen-disallow-host-namespaces`) must be listed explicitly if you want to target only specific rules.
- **Wildcard name patterns** work identically to how they work in inline excludes — `neuvector-enforcer-pod*` matches the same pods either way.
- **`enabled` flag** preserves the addon-gated conditional behavior. When `false`, the subchart skips rendering the PolicyException entirely.

### Existing proof of concept

The pattern is already demonstrated in `tests/test-values.yaml` (lines 704–733):

```yaml
additionalPolicyExceptions:
  testpolicyexception:
    enabled: true
    kind: PolicyException
    namespace: "kyverno"
    annotations:
      policies.kyverno.io/title: Test PolicyException
    spec:
      exceptions:
      - policyName: block-ephemeral-containers
        ruleNames:
        - block-ephemeral-containers
      match:
        any:
        - resources:
            kinds:
            - Pod
            names:
            - important-tool*
      conditions:
        any:
        - key: "{{ request.object.metadata.labels.app || '' }}"
          operator: Equals
          value: busybox
```

---

## 4. Delivery mechanism

No new infrastructure required. The kyverno-policies subchart already supports `.additionalPolicyExceptions` — it renders each entry as a `PolicyException` CR. The Big Bang umbrella chart passes values through to the subchart via `kyvernoPolicies.values`.

### Rendering flow

```
chart/templates/kyverno-policies/values.yaml
  └─ bigbang.defaults.kyverno-policies
       └─ additionalPolicyExceptions:
            └─ <exception-name>:
                 enabled: {{ .Values.<addon>.enabled }}
                 ...
  └─ bigbang.overlays.kyverno-policies
       └─ merges user overrides from kyvernoPolicies.values
            └─ kyverno-policies subchart
                 └─ renders PolicyException CRs into the cluster
```

The overlay merge engine already concatenates list-type fields. The `additionalPolicyExceptions` map is merged by key, so user-provided exceptions coexist cleanly with BB defaults.

---

## 5. Scope

### In scope: inline `exclude` blocks

All `exclude.any[]` entries in `chart/templates/kyverno-policies/values.yaml` that follow the standard pattern:

```yaml
exclude:
  any:
  - resources:
      namespaces: [...]
      names: [...]
```

This covers 72 addon-gated entries across 21 policies and 20 addons, plus ~8 static (always-on) exclusions.

### Out of scope (separate workstreams)

| Mechanism | Where it appears | Why it's different |
|---|---|---|
| **`parameters.allow`** | `restrict-capabilities` (NET_ADMIN, NET_RAW for Istio), `restrict-host-path-write` (fluentbit paths) | These are allowlist values passed to the policy rule itself, not resource-level exclusions. PolicyException doesn't replace them. |
| **`parameters.disallow`** | `disallow-namespaces` (`bigbang`, `default`) | Blocklist mechanism, same reasoning as above. |
| **`update-automountserviceaccounttokens` allow/deny lists** | Two mutation policies with per-namespace `pods.allow` and `pods.deny` lists | Completely different pattern — these are mutation policies with their own namespace/pod scoping, not validation excludes. |
| **`disallow-nodeport-services` dynamic range loops** | Lines 96–146 of values template | Special case: exclusion list is built dynamically from gateway config using `{{ range }}` over `.Values.istioGateway.values.gateways`. Requires design work to express as static PolicyException entries. Tracked separately. |

### Static exclusions

Static exclusions (not gated behind an addon toggle) are in scope but will be handled in the final phase. These include:

- `add-default-securitycontext`: `kube-system`
- `disallow-istio-injection-bypass`: `istio-system`, `istio-gateway`
- `require-istio-on-namespaces`: `kube-node-lease`, `kube-public`, `kube-system`, `bigbang`, `default`, `flux-system`, `istio-system`, `istio-gateway`
- `require-non-root-group`: `kube-system`
- `require-non-root-user`: `kube-system`

---

## 6. Phasing plan

Work is organized by addon, heaviest hitters first. Each phase is an independently shippable MR.

### Phase 1 — Pilot (`neuvector`, `twistlock`)

| Addon | Exclusion count | Policies affected |
|---|---|---|
| `neuvector` | 10 | `add-default-capability-drop`, `add-default-securitycontext`, `disallow-host-namespaces`, `disallow-privileged-containers`, `require-drop-all-capabilities`, `require-non-root-group`, `require-non-root-user`, `restrict-host-path-mount`, `restrict-host-path-write`, `restrict-volume-types` |
| `twistlock` | 12 | `add-default-capability-drop`, `add-default-securitycontext`, `disallow-host-namespaces`, `disallow-tolerations`, `require-drop-all-capabilities`, `require-non-root-group`, `require-non-root-user`, `restrict-apparmor`, `restrict-capabilities`, `restrict-host-path-mount`, `restrict-host-path-write`, `restrict-selinux-type`, `restrict-volume-types` |

**Why first:** Highest exclusion count. Proves out the pattern at scale. Both are security scanners with similar privilege profiles.

**Deliverables:** PolicyException objects for all `neuvector` and `twistlock` exclusions. Inline excludes retained (dual-run). Unit tests confirming both mechanisms produce equivalent behavior.

### Phase 2 — Log collectors (`fluentbit`, `alloy`)

| Addon | Exclusion count | Policies affected |
|---|---|---|
| `fluentbit` | 8 | `add-default-securitycontext`, `disallow-privileged-containers`, `disallow-tolerations`, `require-non-root-group`, `require-non-root-user`, `restrict-host-path-mount`, `restrict-selinux-type`, `restrict-volume-types` |
| `alloy` | 7 | `add-default-securitycontext`, `require-non-root-group`, `require-non-root-user`, `restrict-capabilities`, `restrict-host-path-mount`, `restrict-selinux-type`, `restrict-volume-types` |

**Why second:** Similar privilege needs (host log access, SELinux overrides). Lessons from Phase 1 inform the approach.

### Phase 3 — Backup and CI (`velero`, `gitlabRunner`)

| Addon | Exclusion count | Policies affected |
|---|---|---|
| `velero` (`deployNodeAgent`) | 8 | `add-default-capability-drop`, `add-default-securitycontext`, `require-drop-all-capabilities`, `require-non-root-group`, `require-non-root-user`, `restrict-host-path-mount`, `restrict-user-id`, `restrict-volume-types` |
| `gitlabRunner` | 5 | `add-default-capability-drop`, `add-default-securitycontext`, `require-drop-all-capabilities`, `require-non-root-group`, `require-non-root-user` |

### Phase 4 — Monitoring and service mesh (`monitoring`, `istioGateway`, `istiod`)

| Addon | Exclusion count | Policies affected |
|---|---|---|
| `monitoring` | 4 | `disallow-auto-mount-service-account-token`, `disallow-tolerations`, `restrict-host-path-mount`, `restrict-volume-types` |
| `istioGateway` | 3 | `disallow-image-tags`, `restrict-image-registries`, `disallow-nodeport-services` (partial — static portion only) |
| `istiod` | 2 | `require-non-root-group`, `disallow-nodeport-services` (partial) |

### Phase 5 — Long tail

| Addon | Exclusion count |
|---|---|
| `gitlab` | 2 |
| `mimir` | 2 |
| `kiali` | 1 |
| `vault` | 1 |
| `mattermost` | 1 |
| `backstage` | 1 |
| `externalSecrets` | 1 |
| `gatekeeper` | 1 |
| `headlamp` | 1 |
| `kyvernoReporter` | 1 |
| `thanos` | 1 |

All low-count addons. Can be batched into a single MR if Phase 1–4 patterns are stable.

### Phase 6 — Static exclusions and cleanup

- Convert static (non-addon-gated) exclusions to PolicyException objects.
- Remove all inline `exclude.any[]` blocks from the values template.
- Remove the `exclude.any[]` concatenation logic from the overlay merge engine (if no longer needed).
- Update documentation and migration guide.

---

## 7. Backward compatibility

### Dual-run period (Phases 1–5)

During migration, both mechanisms coexist:

1. **Inline `exclude`** — remains in the values template, unchanged.
2. **`PolicyException`** — added via `additionalPolicyExceptions`.

Kyverno evaluates both. A resource that matches either mechanism is exempted. This means:

- No behavior change for existing clusters on upgrade.
- The PolicyException can be validated independently before the inline exclude is removed.
- Rollback is trivial: remove the `additionalPolicyExceptions` entries.

### Removal (Phase 6)

Once all PolicyExceptions are validated in CI and at least one release cycle has passed with dual-run:

1. Remove inline `exclude` blocks from the values template.
2. Bump the kyverno-policies subchart version (minor version bump).
3. Document the change in release notes with a migration note for anyone who was relying on the overlay merge engine's `exclude.any[]` concatenation for their own custom exclusions.

### User-provided exclusions

Users who add custom exclusions via `kyvernoPolicies.values.policies.<name>.exclude.any[]` overrides will continue to work during the dual-run period. The release notes for Phase 6 should advise these users to migrate their custom exclusions to `additionalPolicyExceptions` as well.

---

## 8. Acceptance criteria

### Per-phase gate (Phases 1–5)

- [ ] Every inline `exclude` entry for the phase's addons has a corresponding `PolicyException` in `additionalPolicyExceptions`.
- [ ] Each PolicyException uses `enabled: {{ .Values.<addon>.enabled }}` (or the appropriate toggle) so it is only rendered when the addon is active.
- [ ] `helm unittest` passes with no regressions.
- [ ] Template rendering (`helm template`) with the addon enabled produces a valid `PolicyException` manifest that passes `kubectl apply --dry-run=server`.
- [ ] Template rendering with the addon disabled produces no PolicyException for that addon.
- [ ] Inline `exclude` blocks are retained (dual-run).

### Phase 6 gate (cleanup)

- [ ] All inline `exclude.any[]` blocks removed from `chart/templates/kyverno-policies/values.yaml`.
- [ ] `helm unittest` passes.
- [ ] CI pipeline passes on all target platforms (k3d, EKS, RKE2).
- [ ] No `exclude` key remains in any policy section of the rendered kyverno-policies values (verified by template inspection).
- [ ] Release notes document the migration and any action required for users with custom exclusions.

### Project-level

- [ ] All 72 addon-gated exclusions are covered by PolicyException objects.
- [ ] Static exclusions are covered by PolicyException objects.
- [ ] Out-of-scope mechanisms (`parameters.allow`, automount allow/deny, dynamic range loops) are tracked in separate issues.
- [ ] The `disallow-nodeport-services` dynamic loop has a design proposal (even if implementation is deferred).

---

## 9. Verification plan

### Unit tests

Each phase adds Helm unit tests in `chart/unittests/` that verify:

1. **PolicyException rendered when addon enabled.** Template the chart with the addon toggled on; assert the PolicyException manifest exists with correct `policyName`, `ruleNames`, and `match` block.
2. **PolicyException absent when addon disabled.** Template with the addon toggled off; assert no PolicyException for that addon.
3. **Equivalence check.** For each migrated exclusion, the PolicyException's `match.any[].resources` block matches the original `exclude.any[].resources` block (same namespace, same name patterns, same kinds where specified).

### Integration tests

- Deploy Big Bang to a k3d cluster with the migrated addons enabled.
- Verify the addon pods start successfully (not blocked by policy).
- Verify that a pod _without_ a PolicyException is still blocked by the policy (positive enforcement check).
- Verify the PolicyException objects are visible via `kubectl get policyexceptions -A`.

### Regression check

- Run the existing CI suite (`tests/` values for k3d, EKS, RKE2) with no changes to test values.
- Confirm no new policy violations appear in Kyverno admission reports.

### Template diffing

During the dual-run period, render templates with and without the PolicyExceptions and diff the Kyverno policy objects. The `exclude` blocks should be identical (since we haven't removed them yet), and the only net-new objects should be the PolicyException manifests.

---

## Appendix A: Full exclusion inventory

This appendix catalogs every inline exclusion defined in the kyverno-policies defaults. Each entry represents an addon or component exempted from a specific policy when that addon is enabled in `values.yaml`.

**Source of truth:** [`chart/templates/kyverno-policies/values.yaml`](../../chart/templates/kyverno-policies/values.yaml)

### How to read this inventory

Each policy section lists the addons that receive exclusions, the namespace and pod name patterns involved, and a brief rationale. "Static" exclusions apply unconditionally (not gated behind an addon toggle).

---

### `add-default-capability-drop`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `gitlab` | `gitlab` | `webservice-test-runner*` | Test runner pods |
| `gitlabRunner` | `gitlab-runner` | `runner*` | CI runner pods |
| `mimir` | `mimir` | `mimir-mimir-smoke-test*` | Smoke test pods |
| `neuvector` | `neuvector` | `neuvector-enforcer-pod*`, `neuvector-cert-upgrader-job*`, `neuvector-controller-pod*`, `neuvector-scanner-pod*`, `neuvector-prometheus-exporter-pod*` | Host access for network traffic inspection |
| `twistlock` | `twistlock` | `twistlock-console*`, `twistlock-defender-ds*`, `volume-upgrade*` | Runtime scanning |
| `vault` | `vault` | `vault-vault-job-init*` | Init job |
| `velero` | `velero` | `velero-backup-restore-test*` | Backup test pods |

### `add-default-securitycontext`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| _(static)_ | `kube-system` | _(all)_ | Always excluded when policy is active |
| `alloy` | `alloy` | `alloy-alloy-logs*` | Needs journalctl and /var/log access |
| `fluentbit` | `fluentbit` | `fluentbit-fluent-bit*` | Needs journalctl and /var/log access |
| `gitlabRunner` | `gitlab-runner` | `runner-*` | CI jobs requiring root |
| `mattermost` | `mattermost`, `mattermost-operator` | `mattermost-*` | Fails when policy applied |
| `neuvector` | `neuvector` | `neuvector-enforcer-pod-*`, `neuvector-controller-pod-*`, `neuvector-cert-upgrader-job-*` | Root for realtime node scanning |
| `twistlock` | `twistlock` | `twistlock-console*`, `twistlock-defender-ds*`, `volume-upgrade-job*` | Root for node/cluster scanning |
| `velero` (`deployNodeAgent`) | `velero` | `node-agent*` | Root group for host pod directory |

### `disallow-auto-mount-service-account-token`

| Addon | Namespace | Resource Names | Kinds | Rationale |
|---|---|---|---|---|
| `backstage` | `backstage` | `backstage`, `backstage*` | Pod, Deployment, ReplicaSet, ServiceAccount | |
| `externalSecrets` | `external-secrets` | `external-secrets*` | | |
| `gatekeeper` | `gatekeeper-system` | `gatekeeper-audit*`, `gatekeeper-controller-manager*` | Pod, Deployment | |
| `headlamp` | `headlamp` | `headlamp*` | | |
| `kyvernoReporter` | `kyverno-reporter` | `kyverno-reporter*` | Pod, Deployment | |
| `monitoring` (flux controllers) | `flux-system` | `notification-controller*`, `helm-controller*`, `source-controller*`, `kustomize-controller*` | Pod, Deployment, StatefulSet | |
| `thanos` | `thanos` | `thanos-compactor*` | Pod, Deployment, StatefulSet | |

### `disallow-host-namespaces`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `neuvector` | `neuvector` | `neuvector-enforcer-pod*` | Host access for network inspection |
| `twistlock` | `twistlock` | `twistlock-defender-ds*` | Host networking for self-monitoring |

### `disallow-image-tags`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `istioGateway` | `istio-gateway` | `*-ingressgateway`, `*-egressgateway` | Image set to `auto`; istiod injects the correct image at pod creation |

### `disallow-istio-injection-bypass`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| _(static)_ | `istio-system`, `istio-gateway` | _(all)_ | Istio does not inject itself |

### `disallow-nodeport-services`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `istiod` + `istioGateway` | `istio-system`, `istio-gateway` | _(dynamic gateway service names)_ | Istio ingress gateways can legitimately create NodePort services |

> **Note:** This policy uses dynamic `{{ range }}` loops over gateway config to build the exclusion list at template time. It is out of scope for direct PolicyException migration and tracked separately.

### `disallow-privileged-containers`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `fluentbit` | `fluentbit` | `fluentbit-fluent-bit*` | Privileged access for log buffer tailing |
| `neuvector` | `neuvector` | `neuvector-enforcer-pod*`, `neuvector-controller-pod*`, `neuvector-scanner-pod*` | Privileged access for realtime file scanning and container runtime access |

### `disallow-tolerations`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `fluentbit` | `fluentbit` | `fluentbit-fluent-bit*` | Must run on all nodes for log collection |
| `monitoring` | `monitoring` | `monitoring-monitoring-prometheus-node-exporter*` | Must run on all nodes for node metrics |
| `twistlock` | `twistlock` | `twistlock-defender-ds*` | Must run on all nodes for realtime scanning |

### `require-drop-all-capabilities`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `gitlab` | `gitlab` | `webservice-test-runner-*` | Test runner pods |
| `gitlabRunner` | `gitlab-runner` | `runner-*` | CI runner pods |
| `mimir` | `mimir` | `mimir-mimir-smoke-test-*` | Smoke test pods |
| `neuvector` | `neuvector` | `neuvector-enforcer-pod*`, `neuvector-cert-upgrader-job-*`, `neuvector-controller-pod*`, `neuvector-scanner-pod*`, `neuvector-prometheus-exporter-pod*` | Host access for network inspection |
| `twistlock` | `twistlock` | `twistlock-defender-ds*`, `volume-upgrade*` | Runtime scanning |
| `velero` | `velero` | `velero-backup-restore-test*` | Backup test pods |

### `require-istio-on-namespaces`

| Addon | Namespace | Rationale |
|---|---|---|
| _(static)_ | `kube-node-lease`, `kube-public`, `kube-system` | Kubernetes control plane does not use Istio |
| _(static)_ | `bigbang`, `default` | No pods in these namespaces |
| _(static)_ | `flux-system` | Flux is installed prior to Istio |
| _(static)_ | `istio-system`, `istio-gateway` | Istio does not inject itself |

### `require-non-root-group`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| _(static)_ | `kube-system` | _(all)_ | Always excluded when policy is active |
| `alloy` | `alloy` | `alloy-alloy-logs*` | Needs journalctl and /var/log |
| `fluentbit` | `fluentbit` | `fluentbit-fluent-bit*` | Needs journalctl and /var/log |
| `gitlabRunner` | `gitlab-runner` | `runner-*` | CI jobs requiring root |
| `istiod` | `istio-system` | `istiod*` | |
| `neuvector` | `neuvector` | `neuvector-enforcer-pod-*`, `neuvector-controller-pod-*`, `neuvector-cert-upgrader-job-*` | Root for realtime scanning |
| `twistlock` | `twistlock` | `twistlock-defender-ds*`, `volume-upgrade-job*` | Root for node/cluster scanning |
| `velero` (`deployNodeAgent`) | `velero` | `node-agent*` | Root group for host pod directory |

### `require-non-root-user`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| _(static)_ | `kube-system` | _(all)_ | Always excluded |
| `alloy` | `alloy` | `alloy-alloy-logs*` | Needs journalctl and /var/log |
| `fluentbit` | `fluentbit` | `fluentbit-fluent-bit*` | Needs journalctl and /var/log |
| `gitlabRunner` | `gitlab-runner` | `runner-*` | CI jobs requiring root |
| `kiali` | `kiali` | `kiali-*` | Operator needs root to deploy Kiali server |
| `neuvector` | `neuvector` | `neuvector*` | Privileged for realtime scanning |
| `twistlock` | `twistlock` | `twistlock-defender-ds*`, `volume-upgrade-job*` | Root for node/cluster scanning |
| `velero` (`deployNodeAgent`) | `velero` | `node-agent*` | Root user for host pod directory |

### `restrict-apparmor`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `twistlock` | `twistlock` | `twistlock-defender-ds*` | Uses `unconfined` appArmor profile |

### `restrict-capabilities`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `alloy` | `alloy` | `alloy-alloy-metrics*`, `alloy-alloy-receiver*`, `alloy-alloy-logs*`, `alloy-alloy-singleton*` | |
| `twistlock` | `twistlock` | `twistlock-defender-ds*` | Needs NET_ADMIN, NET_RAW, SYS_ADMIN, SYS_PTRACE, SYS_CHROOT, MKNOD, SETFCAP, IPC_LOCK |

> **Note:** Istio's NET_ADMIN and NET_RAW are handled globally via `parameters.allow`, not as a per-pod exclusion.

### `restrict-host-path-mount`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `alloy` | `alloy` | `alloy-alloy-logs*` | Mounts /var/log, /var/lib/docker/containers |
| `fluentbit` | `fluentbit` | `fluentbit-fluent-bit*` | Mounts /var/log, /var/lib/docker/containers, /etc/machine-id, /var/log/flb-storage |
| `monitoring` | `monitoring` | `monitoring-monitoring-prometheus-node-exporter*` | Mounts /, /proc, /sys for node metrics |
| `neuvector` | `neuvector` | `neuvector-enforcer-pod*`, `neuvector-cert-upgrader-job-*`, `neuvector-controller-pod*` | Mounts /var/neuvector, /var/run, /proc, /sys/fs/cgroup |
| `twistlock` | `twistlock` | `twistlock-defender-ds*` | Dynamic mounts created at runtime |
| `velero` (`deployNodeAgent`) | `velero` | `node-agent*` | Host pod runtime directory |

### `restrict-host-path-write`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `neuvector` | `neuvector` | `neuvector-controller-pod*`, `neuvector-enforcer-pod*` | Writable /var/neuvector for buffering and state |
| `twistlock` | `twistlock` | `twistlock-defender-ds*` | Writable /dev/log, /var/lib/twistlock, /run, /var/lib/containers, /var/log/audit |

> **Note:** Fluentbit uses `parameters.allow` for /var/log/flb-storage/ and /var/log rather than an exclude block.

### `restrict-image-registries`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `istioGateway` | `istio-gateway` | `*-ingressgateway`, `*-egressgateway` | Image set to `auto`; istiod injects the correct image at pod creation |

### `restrict-selinux-type`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `alloy` | `alloy` | `alloy-alloy-logs-*` | Needs SELinux type `spc_t` for host volume mounting |
| `fluentbit` | `fluentbit` | `fluentbit-fluent-bit*` | Needs SELinux type `spc_t` |
| `twistlock` | `twistlock` | `twistlock-defender-ds*` | Needs SELinux type `spc_t` |

### `restrict-user-id`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `velero` (`deployNodeAgent`) | `velero` | `node-agent*` | Root user for host pod directory |

### `restrict-volume-types`

| Addon | Namespace | Resource Names | Rationale |
|---|---|---|---|
| `alloy` | `alloy` | `alloy-alloy-logs*` | HostPath for /var/log, /var/lib/docker/containers |
| `fluentbit` | `fluentbit` | `fluentbit-fluent-bit*` | HostPath for log tailing and buffering |
| `monitoring` | `monitoring` | `monitoring-monitoring-prometheus-node-exporter*` | HostPath for /proc, /sys |
| `neuvector` | `neuvector` | `neuvector-enforcer-pod*`, `neuvector-controller-pod*` | HostPath volumes for runtime monitoring |
| `twistlock` | `twistlock` | `twistlock-defender-ds*` | HostPath for node logs, syslog, docker daemon |
| `velero` (`deployNodeAgent`) | `velero` | `node-agent*` | HostPath for host pod runtime directory |

---

## Appendix B: Policies without conditional exclusions

These policies exist in the kyverno-policies defaults but have no addon-gated exclude blocks:

| Policy | Notes |
|---|---|
| `disallow-namespaces` | Uses `parameters.disallow` (`bigbang`, `default`) |
| `require-image-signature` | Disabled by default |
| `require-labels` | Audit-only, no excludes |
| `restrict-host-path-mount-pv` | Enforce, no excludes |

## Appendix C: Policies using different mechanisms

The following policies use namespace/pod allow-deny lists rather than `exclude` blocks. They are a different pattern and are tracked as separate workstreams:

- **`update-automountserviceaccounttokens-default`** — Lists namespaces where the default ServiceAccount token should be patched.
- **`update-automountserviceaccounttokens`** — Per-namespace pod allow/deny lists controlling which pods may automount tokens.

## Appendix D: Summary by addon

Addons sorted by how many policies they need exclusions from:

| Addon | Exclusion count | Migration phase |
|---|---|---|
| `neuvector` | 10 | Phase 1 |
| `twistlock` | 12 | Phase 1 |
| `fluentbit` | 8 | Phase 2 |
| `velero` (`deployNodeAgent`) | 8 | Phase 3 |
| `alloy` | 7 | Phase 2 |
| `gitlabRunner` | 5 | Phase 3 |
| `monitoring` | 4 | Phase 4 |
| `istioGateway` | 3 | Phase 4 |
| `gitlab` | 2 | Phase 5 |
| `mimir` | 2 | Phase 5 |
| `istiod` | 2 | Phase 4 |
| `kiali` | 1 | Phase 5 |
| `vault` | 1 | Phase 5 |
| `mattermost` | 1 | Phase 5 |
| `backstage` | 1 | Phase 5 |
| `externalSecrets` | 1 | Phase 5 |
| `gatekeeper` | 1 | Phase 5 |
| `headlamp` | 1 | Phase 5 |
| `kyvernoReporter` | 1 | Phase 5 |
| `thanos` | 1 | Phase 5 |

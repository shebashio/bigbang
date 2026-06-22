# Migrating Kyverno Policies to CEL-Based Policies for Big Bang 4.0

Big Bang 4.0 ships a rebuilt `kyverno-policies` package. The Kubernetes policies
it deploys are no longer Kyverno `ClusterPolicy` resources. They are Kyverno's
newer, CEL-based policy CRDs (`ValidatingPolicy`, `MutatingPolicy`,
`GeneratingPolicy`, `ImageValidatingPolicy`), and policy exceptions are now
`PolicyException` resources in the `policies.kyverno.io/v1` API group.

This guide explains **why** the change is happening, **what** changed, and **how
to update your `kyvernoPolicies` values** so your policy tuning and exceptions
keep working.

> **Who needs to read this?** Anyone who sets anything under
> `kyvernoPolicies.values` in their Big Bang configuration: custom
> `validationFailureAction`, policy `parameters`, per-policy `exclude` blocks,
> `additionalPolicies`, or `additionalPolicyExceptions`. If you deploy
> `kyvernoPolicies` with defaults and never override policy behavior, no action
> is required.

## Why This Change

Kyverno is deprecating the original `ClusterPolicy` API in favor of a family of
purpose-built, CEL-based policy types:

- The new CEL-based `ValidatingPolicy` and `ImageValidatingPolicy` types were
  introduced in Kyverno **v1.14** (April 2025).
- `MutatingPolicy`, `GeneratingPolicy`, and `DeletingPolicy` followed in
  **v1.15** (July 2025).
- Kyverno **1.16** (November 2025) shipped these types at `v1beta1`.
- Kyverno **1.17** (February 2026) promoted them to **`v1` (GA / production
  ready)** and formally **marked `ClusterPolicy` as deprecated**.
- Kyverno **1.20** (planned for **October 2026**) **removes the legacy
  `ClusterPolicy` API entirely.** Versions 1.18 and 1.19 receive only critical
  fixes for the legacy API in the interim.

The move to [CEL (Common Expression
Language)](https://kubernetes.io/docs/reference/using-api/cel/) mirrors the
direction of upstream Kubernetes (ValidatingAdmissionPolicy) and brings several
benefits: policies evaluate in-process without the older engine's overhead, each
policy type does exactly one thing (validate, mutate, generate, or verify
images) instead of a single `ClusterPolicy` mixing rule types, and the
expression language is shared with native Kubernetes admission.

Because the legacy `ClusterPolicy` API is scheduled to be removed outright in
Kyverno 1.20, Big Bang is moving to the CEL-based policies now so that clusters
are not stranded on an API that is about to disappear. **Big Bang 4.0 is the
release that makes the switch.**

## What Big Bang 4.0 Supports

Big Bang 4.0 deploys the CEL-based policies and `PolicyException` CRDs
**exclusively**. Legacy `ClusterPolicy` resources and the legacy `kyverno.io/v2`
`PolicyException` are no longer rendered, and the Kyverno engine shipped with
4.0 supports the `policies.kyverno.io/v1` types natively.

There is no legacy fallback. Any `kyvernoPolicies` configuration written for the
old ClusterPolicy model (per-policy `exclude` blocks, `additionalPolicies` of
`kind: ClusterPolicy`, legacy `additionalPolicyExceptions`, and the moved or
removed global settings) **must be updated** to the new model described below.

To keep a stale values file from quietly doing nothing, the `kyverno-policies`
chart ships a values schema that **rejects legacy configuration at install
time** (that is, the `kyverno-policies` HelmRelease fails to reconcile with a
schema error rather than installing and silently dropping the setting). The
following all fail loudly:

- the top-level `exclude`, `excludeContainers`, and `policyPreconditions` keys;
- a per-policy `exclude` block (`policies.<name>.exclude`);
- an `additionalPolicies` entry with `kind: ClusterPolicy` or `kind: Policy`;
- an `additionalPolicyExceptions` entry that sets a top-level `apiVersion` or
  `kind` field (the legacy `kyverno.io/v2` exceptions carried these; the new
  ones must not);
- an `additionalPolicyExceptions` entry whose `spec` uses the legacy
  `kyverno.io/v2` fields: `spec.exceptions`, `spec.match`, `spec.conditions`,
  `spec.podSecurity`, or `spec.background`.

The schema blocks the known legacy fields specifically rather than fully
validating the new spec, so a spec that is malformed in some other way (for
example, one missing `policyRefs` entirely) still passes Helm and is caught by
Kyverno's own CRD validation when the `PolicyException` is applied. Either way
an un-migrated exception does not quietly succeed. Migrate legacy entries using
section 3 below.

## What Changed at a Glance

| Area | Big Bang 3.x (ClusterPolicy) | Big Bang 4.x (CEL) |
| --- | --- | --- |
| Policy resources | `ClusterPolicy` (`kyverno.io/v1`) | `ValidatingPolicy`, `MutatingPolicy`, `GeneratingPolicy`, `ImageValidatingPolicy` (`policies.kyverno.io/v1`) |
| Policy exceptions | `PolicyException` (`kyverno.io/v2`) with `exceptions[].policyName` + `ruleNames` + `match` | `PolicyException` (`policies.kyverno.io/v1`) with `policyRefs` + CEL `matchConditions` |
| Per-policy exclusions | `policies.<name>.exclude` (any/all blocks) | `additionalPolicyExceptions` (`PolicyException`) or `policies.<name>.excludeNamespaces` |
| Global namespace exclude | `exclude.any[].resources.namespaces` | `policies.excludeNamespaces` |
| Global container exclude | `excludeContainers` (top level) | `policies.excludeContainers` |
| Per-policy preconditions | `policyPreconditions` | Per-policy `matchConditions` (CEL) |
| Custom policies | `additionalPolicies` with `kind: ClusterPolicy`/`Policy` | `additionalPolicies` with `kind: ValidatingPolicy`/`MutatingPolicy`/`GeneratingPolicy`/`ImageValidatingPolicy`/`DeletingPolicy` |
| Policy tuning (`validationFailureAction`, `parameters`) | `policies.<name>.*` | `policies.<name>.*` (same key; see notes below) |

The single most important thing to know: **the top-level `policies` key and the
policy names did not change.** In both 3.x and 4.x you configure a policy at
`kyvernoPolicies.values.policies.<policy-name>` (for example
`policies.restrict-image-registries`). What changed is the *shape* of a few
fields inside that block, and, most significantly, how you write **exceptions**.

## Background: The New Policy Model

### Policy types

The old `ClusterPolicy` is replaced by four policy kinds (all in the
`policies.kyverno.io/v1` API group). You need to know a policy's kind only when
you reference it in an exception (`spec.policyRefs[].kind`):

| Kind | What it does | Big Bang examples |
| --- | --- | --- |
| `ValidatingPolicy` | Allows or denies resources | `restrict-image-registries`, `disallow-privileged-containers`, `require-non-root-user` |
| `MutatingPolicy` | Modifies resources | `add-default-capability-drop`, `update-automountserviceaccounttokens` |
| `GeneratingPolicy` | Creates related resources | `clone-configs` |
| `ImageValidatingPolicy` | Verifies image signatures | `require-image-signature` |

The policies keep the same names as before, so a `ValidatingPolicy` named
`restrict-image-registries` replaces the old `ClusterPolicy` named
`restrict-image-registries`.

Big Bang's `kyverno-policies` chart exposes the same values-level knobs you
already use (`enabled`, `validationFailureAction`, `parameters`, etc.), so you
do not need to write raw CEL policy specs for the built-in policies. The one
place you write CEL is the `matchConditions` of an **exception** (covered
below).

### The new PolicyException

CEL policies use a **new** `PolicyException` (`policies.kyverno.io/v1`) that is
shaped differently from the legacy `kyverno.io/v2` exception. These are two
distinct API groups, not two versions of the same resource: `kyverno.io` is the
older JMESPath engine and `policies.kyverno.io` is the newer CEL engine. The
legacy exception referenced a policy by name and *rule name* and matched
resources with a JMESPath-style `match`/`conditions` block. The new exception
references one or more policies by `name` **and `kind`**, and selects resources
with **CEL `matchConditions`**:

```yaml
# NEW (policies.kyverno.io/v1)
spec:
  policyRefs:
    - name: restrict-image-registries
      kind: ValidatingPolicy
  matchConditions:
    - name: my-workload
      expression: >-
        object.metadata.namespace == 'my-namespace' &&
        object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('my-workload-')
```

The legacy `exceptions[].policyName` + `ruleNames` + `match` structure does
**not** work against CEL policies. Rule names in particular no longer exist; CEL
policies are not composed of named rules.

## How to Migrate Your `kyvernoPolicies` Values

Everything below is configured under `kyvernoPolicies.values` in your Big Bang
values (or a package overlay). Work through the sections that apply to you.

### 1. Policy tuning (`validationFailureAction`, `parameters`)

`validationFailureAction` is unchanged. Continue to use `Enforce`, `Audit`, or
`Warn` per policy:

```yaml
kyvernoPolicies:
  values:
    policies:
      restrict-host-ports:
        validationFailureAction: Audit   # unchanged
```

> **Watch the capitalization.** The value is now matched **case-sensitively**.
> `Enforce` and `Warn` must be capitalized exactly; any other spelling,
> including lowercase `enforce` or `warn`, silently falls through to `Audit`. If
> you relied on lowercase values in 3.x (the legacy engine was
> case-insensitive), a workload you expected to be *enforced* will instead only
> be *audited*. Grep your overrides for `validationFailureAction` and normalize
> the casing.

Several `parameters` blocks changed shape and need updating.

**Glob and wildcard matching became RE2 regex.** In 3.x, policies that matched
labels, annotations, taints, IPs, sysctls, or host paths used shell-style globs
(`*` and `?`). In 4.x those match with [RE2 regular
expressions](https://github.com/google/re2/wiki/Syntax), auto-anchored with
`^`...`$`. This affects `require-labels`, `disallow-labels`,
`require-annotations`, and `disallow-annotations` (their `{key, value}`
entries); `disallow-tolerations` (its `{key, value, effect}` entries); and
`restrict-external-ips`, `restrict-sysctls`, `restrict-host-path-mount`,
`restrict-host-path-write`, and `restrict-host-path-mount-pv` (their pattern
lists). A value with no wildcards still matches literally, so exact strings
carry over unchanged. Rewrite the entries that used `*` or `?`:

| 3.x glob | 4.x RE2 regex |
| --- | --- |
| `192.168.0.?*` | `192\.168\.0\..+` |
| `team-*` | `team-.*` |
| `*-canary` | `.*-canary` |

Each of these stays a flat list; only the entry values change. Here is one of
them, `restrict-external-ips` (the dots in an IP must be escaped, since `.`
matches any character in a regex):

```yaml
# BEFORE (3.x)
policies:
  restrict-external-ips:
    parameters:
      allow:
        - 192.168.0.?*
        - 10.0.0.5

# AFTER (4.x)
policies:
  restrict-external-ips:
    parameters:
      allow:
        - 192\.168\.0\..+
        - 10\.0\.0\.5
```

The label and annotation policies also changed structurally, from bare strings
(optionally `"key: value"`) to `{key, value}` objects. `require-labels` shows
the shape (the same applies to `disallow-labels`, `require-annotations`, and
`disallow-annotations`): a bare `key` requires the label to be present with any
non-empty value, and adding a `value` constrains what it must be set to.

```yaml
# BEFORE (3.x)
policies:
  require-labels:
    parameters:
      require:
        - app.kubernetes.io/name
        - "app.kubernetes.io/managed-by: Helm"

# AFTER (4.x)
policies:
  require-labels:
    parameters:
      require:
        - key: app.kubernetes.io/name
        - key: app.kubernetes.io/managed-by
          value: Helm
```

**`restrict-host-ports`**: the allow list is now a list of `{min, max}` ranges
(both inclusive) instead of individual port values. An individual port becomes a
range where `min` equals `max`, and a contiguous range that previously required
listing every port can now be a single entry.

```yaml
# BEFORE (3.x)
policies:
  restrict-host-ports:
    parameters:
      allow:
        - 443
        - 8443

# AFTER (4.x)
policies:
  restrict-host-ports:
    parameters:
      allow:
        - min: 443
          max: 443
        - min: 8443
          max: 8443
```

**`restrict-image-registries`** now matches by prefix. The `allow` list is still
a plain list, but each entry is a literal registry **prefix** (matched with
`startsWith`), not a glob. Drop any trailing `*`.

```yaml
# BEFORE (3.x)
policies:
  restrict-image-registries:
    parameters:
      allow:
        - registry1.dso.mil*
        - registry.dso.mil*

# AFTER (4.x)
policies:
  restrict-image-registries:
    parameters:
      allow:
        - registry1.dso.mil
        - registry.dso.mil
```

If you set `parameters` on any other policy, confirm the shape against the
[`kyverno-policies`
chart](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies)'s
`chart/values.yaml`, which documents every policy's parameters inline.

### 2. Global settings

Several top-level keys moved under `policies` or were removed:

| Big Bang 3.x | Big Bang 4.x |
| --- | --- |
| `exclude.any[].resources.namespaces: [kube-system]` | `policies.excludeNamespaces: [kube-system]` |
| `excludeContainers: [istio-init]` | `policies.excludeContainers: [istio-init]` |
| `policyPreconditions: {...}` | Per-policy `policies.<name>.matchConditions` (CEL) |

```yaml
# BEFORE (3.x)
kyvernoPolicies:
  values:
    exclude:
      any:
        - resources:
            namespaces:
              - kube-system
    excludeContainers:
      - istio-init

# AFTER (4.x)
kyvernoPolicies:
  values:
    policies:
      excludeNamespaces:
        - kube-system
      excludeContainers:
        - istio-init
```

`excludeNamespaces` and `excludeContainers` can also be set **per policy** under
`policies.<name>.excludeNamespaces` / `.excludeContainers`, and per-policy
values are merged with the globals.

> **Note on scope:** `excludeNamespaces` only covers exclusion **by namespace
> name**. The old `exclude` block could also match on resource names, subjects,
> cluster roles, and roles. For anything beyond a plain namespace-name
> exclusion, use an `additionalPolicyExceptions` entry (next section).

### 3. Exceptions (the biggest change)

Exceptions are where the model changed the most. However you exempted a workload
in 3.x, it now becomes an `additionalPolicyExceptions` entry: a
`policies.kyverno.io/v1` `PolicyException` that lists the policies to exempt in
`spec.policyRefs` (by `name` and `kind`) and selects the workload with a CEL
`spec.matchConditions` expression. There are two 3.x starting points.

#### From a per-policy `exclude` block

In 3.x you carved a workload out of a policy with a per-policy `exclude` block:

```yaml
# BEFORE (3.x): exclude a workload from several policies
kyvernoPolicies:
  values:
    policies:
      restrict-host-path-mount:
        exclude:
          any:
            - resources: &my-app
                namespaces:
                  - my-namespace
                names:
                  - my-app*
      require-non-root-user:
        exclude:
          any:
            - resources: *my-app
```

In 4.x this is a single `additionalPolicyExceptions` entry that lists every
policy the workload needs exempting from:

```yaml
# AFTER (4.x)
kyvernoPolicies:
  values:
    additionalPolicyExceptions:
      my-app:
        # Optional metadata/annotations for documentation
        metadata:
          annotations:
            policies.kyverno.io/description: >-
              Allows my-app to mount host paths and run as root.
        spec:
          policyRefs:
            - name: restrict-host-path-mount
              kind: ValidatingPolicy
            - name: require-non-root-user
              kind: ValidatingPolicy
          matchConditions:
            - name: my-app
              expression: >-
                object.metadata.namespace == 'my-namespace' &&
                object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('my-app')
```

#### From a legacy `additionalPolicyExceptions` entry

If you already had `additionalPolicyExceptions` entries in 3.x, they used the
legacy `kyverno.io/v2` shape and must be rewritten:

```yaml
# BEFORE (3.x, legacy kyverno.io/v2)
additionalPolicyExceptions:
  my-exception:
    spec:
      exceptions:
        - policyName: restrict-image-registries
          ruleNames:
            - validate-registries
            - autogen-validate-registries
      match:
        any:
          - resources:
              kinds: [Pod, Deployment]
              namespaces: [my-namespace]
              names: [my-app*]

# AFTER (4.x, policies.kyverno.io/v1)
additionalPolicyExceptions:
  my-exception:
    spec:
      policyRefs:
        - name: restrict-image-registries
          kind: ValidatingPolicy
      matchConditions:
        - name: my-app
          expression: >-
            object.metadata.namespace == 'my-namespace' &&
            object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('my-app')
```

The chart no longer accepts per-entry `apiVersion`/`kind` overrides; every
`additionalPolicyExceptions` entry renders as a `policies.kyverno.io/v1`
`PolicyException`. Drop `spec.exceptions`, `ruleNames`, and `match`; use
`policyRefs` and `matchConditions` instead. You no longer reference rule names
(CEL policies have none), and you no longer need to enumerate resource `kinds`;
Kyverno's autogen applies the exception across a workload and its Pods.

#### Notes for both

- `policyRefs` must include the correct **`kind`** for each policy. Most
  Pod-Security policies are `ValidatingPolicy`; the `add-default-*` and
  `update-*` policies are `MutatingPolicy`; `clone-configs` is a
  `GeneratingPolicy`; `require-image-signature` is an `ImageValidatingPolicy`.
- There is **no wildcard `policyRef`**. If a workload trips a dozen policies,
  list all dozen (see the built-in per-package exceptions Big Bang ships for
  reference).

#### Writing the `matchConditions` expression

`matchConditions` is the one place you must write CEL, and there is one gotcha
worth knowing. Controller-created Pods (from Deployments and their ReplicaSets,
DaemonSets, and Jobs) are admitted with `metadata.name` **absent** and only
`metadata.generateName` set. Reading `object.metadata.name` directly throws on
those Pods and the exemption silently fails, so match the effective name
instead:

```text
object.metadata.?name.orValue(object.metadata.?generateName.orValue(''))
```

Then call `.startsWith('prefix')` or `.contains('substr')` on it. Because a
`generateName` ends in a trailing `-` (e.g. `my-app-`), convert an exact legacy
`== 'my-app'` to `.startsWith('my-app')`, and convert `endsWith('-x')` to
`.contains('-x')`.

Example combining several workloads in one namespace:

```yaml
matchConditions:
  - name: my-workloads
    expression: >-
      object.metadata.namespace == 'my-namespace' && (
        object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('frontend-') ||
        object.metadata.?name.orValue(object.metadata.?generateName.orValue('')).startsWith('backend-')
      )
```

### 4. Custom policies (`additionalPolicies`)

If you ship your own policies through `additionalPolicies`, two things changed:

- `kind` must now be one of `ValidatingPolicy`, `MutatingPolicy`,
  `GeneratingPolicy`, `ImageValidatingPolicy`, or `DeletingPolicy` (no longer
  `ClusterPolicy` / `Policy`).
- `spec` must be a CEL policy spec for that kind, not a `ClusterPolicy` rules
  block. See the [Kyverno policy types
  overview](https://kyverno.io/docs/policy-types/overview/) for the spec of each
  kind.

## Reference: Complete Values Field Mapping

| Big Bang 3.x (`kyvernoPolicies.values.…`) | Big Bang 4.x (`kyvernoPolicies.values.…`) |
| --- | --- |
| `policies.<name>.enabled` | `policies.<name>.enabled` (unchanged) |
| `policies.<name>.validationFailureAction` | `policies.<name>.validationFailureAction` (unchanged) |
| `policies.<name>.parameters.*` | `policies.<name>.parameters.*` (several changed shape: the glob-to-regex family, `restrict-host-ports` ranges, `restrict-image-registries` prefixes; see section 1) |
| `policies.<name>.exclude` | `additionalPolicyExceptions.<name>` or `policies.<name>.excludeNamespaces` |
| `exclude` (global) | `policies.excludeNamespaces` |
| `excludeContainers` (global) | `policies.excludeContainers` |
| `policyPreconditions` | `policies.<name>.matchConditions` |
| `failurePolicy` | `failurePolicy` (unchanged); per-policy via `policies.vpolFailurePolicy` / `policies.mpolFailurePolicy` |
| `background` | `background` (unchanged); per-policy via `policies.background` |
| `webhookTimeoutSeconds` | `webhookTimeoutSeconds` (unchanged); per-policy via `policies.webhookTimeoutSeconds` |
| `autogenControllers` | `autogenControllers` (unchanged); per-policy via `policies.autogenControllers` |
| `additionalPolicies.<n>.kind: ClusterPolicy` | `additionalPolicies.<n>.kind: ValidatingPolicy` (or other CEL kind) |
| `additionalPolicyExceptions.<n>.spec.exceptions/match` | `additionalPolicyExceptions.<n>.spec.policyRefs/matchConditions` |

## Troubleshooting

**The `kyverno-policies` HelmRelease fails to reconcile with a values schema
error.** A stale legacy key is present. The chart's schema rejects top-level
`exclude`/`excludeContainers`/`policyPreconditions`, per-policy
`policies.<name>.exclude` blocks, and `additionalPolicies` of `kind:
ClusterPolicy`/`Policy`. Read the error to find the offending key and re-express
it in the new model: per-policy `exclude` blocks become
`additionalPolicyExceptions` entries (section 3) or `excludeNamespaces` (section
2); global settings move per section 2; custom policies move per section 4.

**My exception isn't taking effect.** Check that (a) the `policyRefs[].kind`
matches the policy's real kind (a `MutatingPolicy` referenced as
`ValidatingPolicy` will not match), and (b) the `matchConditions` expression
matches controller-created Pods via the effective-name pattern above. Reading
`object.metadata.name` unguarded is the most common cause of a silently
non-matching exception.

**The schema rejects my `additionalPolicyExceptions` entry.** The entry still
uses the legacy `kyverno.io/v2` shape. Two things trigger this: a top-level
`apiVersion` or `kind` field (the chart now hardcodes `policies.kyverno.io/v1` /
`PolicyException`, so remove them and set the policy kind inside
`spec.policyRefs[].kind`), or a legacy `spec` body using `spec.exceptions`,
`spec.match`, `spec.conditions`, `spec.podSecurity`, or `spec.background`
(rewrite it with `spec.policyRefs` + `spec.matchConditions` per section 3).

**A policy I set to `enforce` is only auditing.** `validationFailureAction` is
now case-sensitive. Use `Enforce`/`Warn`/`Audit` with exact capitalization;
lowercase values silently downgrade to `Audit` (section 1).

## References

- [Kyverno: Migrating to CEL Policies](https://kyverno.io/docs/guides/migration-to-cel/)
- [Kyverno: Policy Types overview](https://kyverno.io/docs/policy-types/overview/)
- [Announcing Kyverno Release 1.17!](https://kyverno.io/blog/2026/02/02/announcing-kyverno-release-1.17/): CEL policies GA, ClusterPolicy deprecated
- [Announcing Kyverno Release 1.16!](https://kyverno.io/blog/2025/11/10/announcing-kyverno-release-1.16/)
- [CEL in Kubernetes](https://kubernetes.io/docs/reference/using-api/cel/)
- Big Bang [`kyverno-policies` package](https://repo1.dso.mil/big-bang/product/packages/kyverno-policies): `chart/values.yaml` documents every policy and its parameters inline

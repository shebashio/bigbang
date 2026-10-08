# Migrating package values for Big Bang 4.0

Big Bang 4.0 consolidates built-in and user-supplied package configuration under `packages.<name>`. Starting with Big Bang 3.32, Big Bang 3.x accepts both the old and new package paths. The `packageConfiguration.version: v1` discriminator produced by this migration remains supported and becomes the default package contract in Big Bang 4.x.

This guide and `scripts/migrate-values-3-to-4.sh` cover the package-path migration and the related `bb-common` values migration. In Big Bang 4.x, every built-in package consumes `bb-common` as a subchart, so target 4 moves `istio`, `networkPolicies`, and `routes` beneath the `bb-common` subchart key. Target 4 also removes the legacy Istio hardening configuration after migrating its custom ServiceEntries and AuthorizationPolicies to their 4.x locations. The script preserves but does not rewrite other deprecated Big Bang settings or child-chart values, including legacy `hostname` and SSO settings. Follow the applicable release notes and deprecation notices for those migrations.

The required `--target` option controls which parts of the migration run. Use
`--target 3` to adopt only the unified `packages.<name>` paths on Big Bang 3.32
or a later 3.x release. This retains the flat `bb-common` library values and
legacy hardening settings required by 3.x. Use `--target 4` when preparing
values for Big Bang 4.x; it also applies the `bb-common` subchart layout and
removes legacy hardening. Do not deploy target 4 output to a 3.x release.

For complete command syntax, option behavior, input formats, safety controls,
and troubleshooting, see the
[Package Values Migration Script Reference](package-values-migration-script.md).

Run the migration script with [Mike Farah yq v4](https://github.com/mikefarah/yq) installed:

```shell
scripts/migrate-values-3-to-4.sh --target 4 --output values-4.x.yaml values.yaml
```

By default, the script writes migrated YAML to standard output and leaves its
inputs unchanged. When using shell redirection, never redirect output to an
input file because the shell truncates the destination before the script can
validate it.

```shell
scripts/migrate-values-3-to-4.sh --target 4 values.yaml > values-4.x.yaml
```

For a GitOps deployment that supplies multiple values files, pass every file in
the same order used by Helm. The script composes the inputs first, with later
files taking precedence, and writes one consolidated migrated document. This
preserves the effective values when legacy and canonical paths occur in
different layers.

```shell
scripts/migrate-values-3-to-4.sh --output values-4.x.yaml \
  --target 4 \
  base.yaml environment.yaml secrets.yaml
```

To replace the input, use `--in-place`. This mode first creates `values.yaml.bak` and refuses to overwrite an existing backup:

```shell
scripts/migrate-values-3-to-4.sh --target 4 --in-place values.yaml
```

For either target, the script selects the durable unified package contract by setting `packageConfiguration.version: v1`, which enables the canonical-package preview in Big Bang 3.32 and later 3.x releases, then moves known top-level built-in packages and packages under `addons` into the unified map. Non-conflicting custom packages and unrelated values are preserved. If both the legacy and unified paths configure a package, their maps are recursively merged and `packages.<name>` takes precedence, matching Big Bang 3.x compatibility behavior.

With `--target 4`, the script additionally moves each built-in package's `values.istio`, `values.networkPolicies`, and `values.routes` configuration beneath `values.bb-common`. If both flat and already-nested `bb-common` values exist, they are recursively merged and the nested values take precedence. With `--target 3`, these values remain flat for compatibility with the `bb-common` library chart.

## Decrypted Kubernetes Secrets

Use `--secret-key` when a decrypted Kubernetes Secret stores Big Bang values
under `stringData` or base64-encoded `data`. The command preserves the Secret
envelope and migrates only the selected values payload:

```shell
scripts/migrate-values-3-to-4.sh \
  --target 4 \
  --secret-key values.yaml \
  --output environment-4.x.yaml environment.yaml
```

Secret mode accepts exactly one input. It rejects ambiguous keys that exist in
both `data` and `stringData`, malformed base64, non-Secret resources, and
SOPS-encrypted documents. Use the SOPS wrapper below when the input is still
encrypted.

The command automatically resolves YAML anchors and aliases in the protected
working copy before migration. It warns and lists each expanded anchor name so
you can review the affected values. The output contains concrete values rather
than recreated anchors. YAML merge keys use spec-compliant precedence, matching
Helm: explicit mapping values override merged values regardless of key order.

## SOPS-encrypted Kubernetes Secrets

Use `scripts/migrate-sops-values-3-to-4.sh` when a SOPS-encrypted Kubernetes
Secret stores Big Bang values under `stringData["values.yaml"]` or
`data["values.yaml"]`. The wrapper decrypts a protected temporary copy, calls
the plaintext migration script's `--secret-key` mode, updates the Secret through
SOPS's editor flow, and verifies the encrypted result by decrypting it again.
Values under `data` are decoded from and restored to base64 automatically.

SOPS authentication is inherited from the environment. For example, to write
a new encrypted file while leaving the input unchanged:

```shell
AWS_PROFILE=development \
  scripts/migrate-sops-values-3-to-4.sh \
  --target 4 \
  --output environment-4.x.enc.yaml environment.enc.yaml
```

To replace the encrypted input, use `--in-place`. This creates an encrypted
`.bak` file before replacing the input and refuses to overwrite an existing
backup:

```shell
AWS_PROFILE=development \
  scripts/migrate-sops-values-3-to-4.sh \
  --target 4 \
  --in-place environment.enc.yaml
```

The Secret key defaults to `values.yaml`. Use `--values-key` when the embedded
values use another key:

```shell
scripts/migrate-sops-values-3-to-4.sh \
  --target 4 \
  --values-key bigbang.yaml \
  --output environment-4.x.enc.yaml environment.enc.yaml
```

The wrapper accepts exactly one Secret because independently migrating layered
values can change precedence when one layer uses a legacy package path and
another uses its canonical `packages.<name>` path. For layered deployments,
inspect every values source in Helm/Flux order. If the same package is
configured through both forms across layers, compose the decrypted values in
that order with `migrate-values-3-to-4.sh --target 3` or `--target 4`, as
appropriate for the destination chart, and review a consolidated output
before changing the stored layers.

The wrapper never sends plaintext to standard output. Plaintext temporary files
are created with restrictive permissions and removed on exit. Re-encryption
uses the input document's existing SOPS metadata and master keys, so no
provider-specific key flags are required beyond the authentication normally
used to edit that file.

Package entries retain their first-appearance order from the effective composed
input. When legacy and canonical paths both configure a package, its first
appearance determines its position without changing canonical-value precedence.

For backward compatibility, the migration utility also recognizes the historical addons.mattermostoperator key, which was renamed to addons.mattermostOperator in Big Bang 1.53. When multiple forms configure the same package, precedence is packages.mattermostOperator, then addons.mattermostOperator, then the historical addons.mattermostoperator key.

Without `packageConfiguration.version: v1`, Big Bang 3.x continues treating every entry under `packages` as a custom package—even when its name matches a built-in package. This opt-in prevents a minor release from silently reinterpreting an existing custom package.

For the same reason, the migration script stops if an unversioned input already contains a `packages.<name>` entry whose name exactly matches a built-in. Rename that custom package before migrating. If the entry was deliberately prepared as a canonical built-in, explicitly set `packageConfiguration.version: v1` first.

The unified contract also reserves the case-folded canonical name, rendered
resource name, and template-directory name of every built-in package. The
migration script applies the same identity checks as chart rendering and
rejects:

- A custom package that normalizes to a built-in identity, such as `KIALI`
  conflicting with `kiali` or `istio-cni` conflicting with `istioCNI`. If the
  entry is intended to configure the built-in, use its exact canonical key and
  set `packageConfiguration.version: v1`; otherwise, rename the custom package.
- Two custom packages that normalize to the same rendered identity, such as
  `examplePackage` and `example-package`. Rename one of the custom packages.

These normalized collision checks also apply when the input already sets
`packageConfiguration.version: v1`.

For example:

```yaml
# Before
monitoring:
  enabled: true
addons:
  gitlab:
    enabled: false
packages:
  podinfo:
    enabled: true
```

becomes:

```yaml
# After
packageConfiguration:
  version: v1
packages:
  monitoring:
    enabled: true
  gitlab:
    enabled: false
  podinfo:
    enabled: true
```

Package values that previously configured the `bb-common` library at the root
of a built-in package's values are scoped to the subchart dependency:

```yaml
# Before
kiali:
  values:
    istio: {}
    networkPolicies: {}
    routes: {}

# After
packages:
  kiali:
    values:
      bb-common:
        istio: {}
        networkPolicies: {}
        routes: {}
```

Unknown custom packages are not rewritten because their `bb-common`
consumption model is owned by the package author.

## Istio hardening changes

With `--target 4`, Big Bang 4.x removes the legacy `hardened` configuration
model. The hardened posture is applied by default, and its individual
behaviors are configured directly through the `bb-common` Istio values instead
of a shared hardening switch.

The migration script makes the following changes:

| Big Bang 3.x value | Big Bang 4.x result |
| --- | --- |
| `istiod.values.hardened` | Removed; there is no direct replacement because the hardened posture is the default. |
| `<package>.values.istio.hardened.enabled` | Removed; there is no direct replacement because the hardened posture is the default. |
| `<package>.values.istio.hardened.customServiceEntries` | Moved to `packages.<package>.values.bb-common.istio.serviceEntries.custom`. |
| `<package>.values.istio.hardened.customAuthorizationPolicies` | Moved to `packages.<package>.values.bb-common.istio.authorizationPolicies.custom`. |

When the destination already contains custom ServiceEntries or
AuthorizationPolicies, the migrated legacy entries are prepended to the
existing entries. All other values beneath the legacy `hardened` key are
removed.

AuthorizationPolicies can be disabled for an individual package when the
default posture is not appropriate. Custom ServiceEntries can likewise be
removed, or individual entries can be disabled when supported by the package:

```yaml
packages:
  kiali:
    values:
      bb-common:
        istio:
          authorizationPolicies:
            enabled: false
            generateFromNetpol: false
            custom: []
          serviceEntries:
            custom: []
```

The script reports non-istiod ServiceEntries migrated from
`hardened.customServiceEntries` for manual review. These entries remain
cluster-wide under `istio.serviceEntries.custom`. If namespace-scoped egress is
sufficient, consider replacing them with package-scoped
`bb-common.routes.outbound` configuration.

Review the output and render it with the chart selected by `--target`: a
compatible Big Bang 3.x chart for target 3, or the Big Bang 4.x chart for target
4. Keep `packageConfiguration.version: v1`; 4.x retains it as the unified
package contract discriminator.

```shell
helm template bigbang ./chart -f values-4.x.yaml > /dev/null
```

The scripts reject inputs that they cannot transform safely:

- `--target` is required and accepts only `3` or `4`.
- The plaintext script rejects SOPS metadata and directs users to
  `migrate-sops-values-3-to-4.sh`.
- The SOPS wrapper requires a Kubernetes Secret with exactly one matching key
  under `data` or `stringData`. It rejects plaintext documents, ambiguous keys,
  malformed base64, and failed decrypt or re-encrypt verification.
- Split multi-document YAML into individual values files and pass them in their
  original order.
- YAML anchors and aliases are expanded automatically. Review the warning and
  list of expanded anchor names; the scripts stop if expansion changes the
  resolved values structure.
- `--output` must name a file, not a directory, and cannot refer to an input
  directly or through a symlink or hardlink. Use `--in-place` for a single input
  when replacement is intended; it creates a backup first.

The script is idempotent: after all known legacy paths have moved, running it again leaves the values unchanged.

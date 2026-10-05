# Migrating package values for Big Bang 4.0

Big Bang 4.0 consolidates built-in and user-supplied package configuration under `packages.<name>`. Starting with Big Bang 3.32, Big Bang 3.x accepts both the old and new package paths. The `packageConfiguration.version: v1` discriminator produced by this migration remains supported and becomes the default package contract in Big Bang 4.x.

This guide and `scripts/migrate-values-3-to-4.sh` cover the package-path migration and the related `bb-common` values migration. In Big Bang 4.x, every built-in package consumes `bb-common` as a subchart, so the script moves `istio`, `networkPolicies`, and `routes` beneath the `bb-common` subchart key. The script also removes the legacy Istio hardening configuration after migrating its custom ServiceEntries and AuthorizationPolicies to their 4.x locations. It preserves but does not rewrite other deprecated Big Bang settings or child-chart values, including legacy `hostname` and SSO settings. Follow the applicable release notes and deprecation notices for those migrations.

Although Big Bang 3.32 supports the unified `packages.<name>` paths, the complete output from this script also contains the 4.x-only `bb-common` subchart layout and hardening changes. Deploy the complete migrated output with Big Bang 4.x rather than applying it independently to a 3.x release.

Run the migration script with [Mike Farah yq v4](https://github.com/mikefarah/yq) installed:

```shell
scripts/migrate-values-3-to-4.sh --output values-4.x.yaml values.yaml
```

By default, the script writes migrated YAML to standard output and leaves its
inputs unchanged. When using shell redirection, never redirect output to an
input file because the shell truncates the destination before the script can
validate it.

```shell
scripts/migrate-values-3-to-4.sh values.yaml > values-4.x.yaml
```

For a GitOps deployment that supplies multiple values files, pass every file in
the same order used by Helm. The script composes the inputs first, with later
files taking precedence, and writes one consolidated migrated document. This
preserves the effective values when legacy and canonical paths occur in
different layers.

```shell
scripts/migrate-values-3-to-4.sh --output values-4.x.yaml \
  base.yaml environment.yaml secrets.yaml
```

To replace the input, use `--in-place`. This mode first creates `values.yaml.bak` and refuses to overwrite an existing backup:

```shell
scripts/migrate-values-3-to-4.sh --in-place values.yaml
```

The script selects the durable unified package contract by setting `packageConfiguration.version: v1`, which enables the canonical-package preview in Big Bang 3.32 and later 3.x releases, then moves known top-level built-in packages and packages under `addons` into the unified map. It also moves each built-in package's `values.istio`, `values.networkPolicies`, and `values.routes` configuration beneath `values.bb-common`. Non-conflicting custom packages and unrelated values are preserved. If both the legacy and unified paths configure a package, their maps are recursively merged and `packages.<name>` takes precedence, matching Big Bang 3.x compatibility behavior. If both flat and already-nested `bb-common` values exist, they are recursively merged and the nested values take precedence.

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

Big Bang 4.x removes the legacy `hardened` configuration model. The hardened
posture is applied by default, and its individual behaviors are configured
directly through the `bb-common` Istio values instead of a shared hardening
switch.

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

Review the output and render it with the Big Bang 4.x chart before adopting it. Keep `packageConfiguration.version: v1`; 4.x retains it as the unified package contract discriminator.

```shell
helm template bigbang ./chart -f values-4.x.yaml > /dev/null
```

The script rejects inputs that it cannot transform safely:

- For SOPS-encrypted values, decrypt to a protected temporary plaintext file,
  migrate it, review it, and re-encrypt it according to your repository's SOPS
  policy. For example:

  ```shell
  sops --decrypt values.enc.yaml > values.decrypted.yaml
  scripts/migrate-values-3-to-4.sh --output values.migrated.yaml values.decrypted.yaml
  sops --encrypt values.migrated.yaml > values.enc.yaml
  ```

  Securely remove the temporary plaintext files after reviewing the encrypted
  result.
- Split multi-document YAML into individual values files and pass them in their
  original order.
- Expand YAML anchors and aliases before migration. Automated rewriting can
  otherwise change their sharing and merge semantics.
- `--output` must name a file, not a directory, and cannot refer to an input
  directly or through a symlink or hardlink. Use `--in-place` for a single input
  when replacement is intended; it creates a backup first.

The script is idempotent: after all known legacy paths have moved, running it again leaves the values unchanged.

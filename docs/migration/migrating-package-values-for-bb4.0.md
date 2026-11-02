# Migrating package values for Big Bang 4.0

Follow the prescribed [4.0 upgrade sequence](migrating-to-bb4.0.md): upgrade to
**Big Bang 3.35.1 first**, then upgrade to **4.0 with Ambient enabled and the
package values migrations applied**. This guide covers preparing the values
for that second upgrade.

Big Bang 4.0 moves built-in package configuration from top-level and
`addons.<name>` paths into `packages.<name>`. Migrated values retain:

```yaml
packageConfiguration:
  version: v1
```

Use the required `--target 4` option for the 4.0 upgrade. It also nests
`values.istio`, `values.networkPolicies`, and `values.routes` beneath
`values.bb-common` and migrates legacy hardening. Do not deploy target 4 output
to Big Bang 3.x. The [script reference](package-values-migration-script.md)
documents the separate target 3 utility behavior.

Canonical package values override legacy aliases, and already-nested
`bb-common` values override flat values. Unknown custom package values are
not rewritten. Other deprecated settings require separate migration according
to the applicable release notes.

Use this guide to choose and run a migration workflow. For complete option
semantics, safeguards, and troubleshooting, see the
[Package Values Migration Script Reference](package-values-migration-script.md).

## Prepare for the 4.0 upgrade

Complete and validate the upgrade to **3.35.1** before preparing the 4.0
configuration. Run the script against the values deployed on 3.35.1:

```shell
scripts/migrate-values-3-to-4.sh --target 4 \
  --output values-4.x.yaml values.yaml
```

Explicitly set `istio.ambient.enabled: true` in the migrated configuration.
Review and render the output against the 4.0 chart, then deploy it together
with the **4.0 version change and Ambient enablement**. Keep target 4 output
off the running 3.35.1 deployment. For layered configurations, use the workflows
below and preserve the effective values order.

The script does not convert custom Kyverno policies, policy parameters,
exclusions, or exceptions to CEL. Follow the separate
[Kyverno policies migration guide](migrating-kyverno-policies-for-bb4.0.md).
The script does not enable Ambient; follow the
[Ambient migration procedure](migrating-istio-to-ambient.md) as part of the
3.35.1-to-4.0 upgrade.

## Requirements

Install:

- Bash.
- `jq`.
- [Mike Farah `yq`](https://github.com/mikefarah/yq) version 4.47.1 or newer.

SOPS-encrypted inputs also require `sops` and access to the document's master
keys. Authentication is inherited from the environment, such as `AWS_PROFILE`
for AWS KMS.

## Choose a workflow

| Input | Migration workflow |
| --- | --- |
| One plaintext values file | Run the plaintext script with `--target 4`. |
| Multiple plaintext files that can become one file | Pass every file in Helm order and write one consolidated output. |
| Values sources that must remain separate | Choose one primary source to own `packageConfiguration.version: v1`; use `--omit-package-configuration` on every secondary source. |
| Parent Big Bang HelmRelease or Kustomize values patch | Use `--bigbang-helmrelease` to migrate `spec.values` and retain the manifest structure. |
| Package HelmRelease patch files | Pass each file with `--helmrelease-patch` to convert supported settings into package values. |
| Decrypted Kubernetes Secret | Use the plaintext script with `--secret-key`. |
| SOPS-encrypted Kubernetes Secret | Use the SOPS wrapper. |

For separately stored values, designate one source to own
`packageConfiguration.version: v1`, and always preserve the order in which
Helm or Flux applies values. Later sources override earlier sources.

## Migrate parent Big Bang HelmRelease patches

If package files identify `metadata.name: bigbang` and contain
`spec.values.monitoring` or `spec.values.addons.argocd`, they configure the
parent Big Bang release. Migrate each file while preserving its wrapper:

```shell
scripts/migrate-values-3-to-4.sh --target 4 \
  --bigbang-helmrelease --omit-package-configuration \
  --output monitoring-4.x.yaml monitoring.yaml
```

This moves package configuration beneath `spec.values.packages`. Metadata,
`valuesFrom`, parent post-renderers, and other fields remain in the manifest.
Package post-renderers move with their package configuration. Existing
Kustomize directory layouts and overlay order can stay intact.

Use `--omit-package-configuration` for secondary patches after designating a
primary values source to supply `packageConfiguration.version: v1`. Omit that
option for a standalone parent manifest. `--in-place` is also supported and
creates an input backup. Files without inline values remain unchanged.

See the [parent HelmRelease reference](package-values-migration-script.md#parent-big-bang-helmreleases-and-values-patches)
for supported inputs and cases requiring manual migration, including JSON
patches and package-map deletions. Referenced Secret and ConfigMap values must
be migrated separately.

## Migrate package HelmRelease patches

Customers who patch the child HelmReleases generated by Big Bang can convert
those overrides to package values:

```shell
scripts/migrate-values-3-to-4.sh --target 4 \
  --output values-4.x.yaml values.yaml \
  --helmrelease-patch monitoring-patch.yaml \
  --helmrelease-patch ek-patch.yaml
```

The script maps `spec.values` to `packages.<name>.values` and supported Flux
settings, such as `timeout` and `upgrade`, to `packages.<name>.flux`. Patches
override the migrated ordinary values; later patches win. Ordinary values files
are optional, and a patch file may contain multiple HelmRelease documents.

Unsupported fields require manual migration. Review the
[supported patch fields and limitations](package-values-migration-script.md#package-helmrelease-patches),
then remove the original patches when adopting the converted values. Validate
the final render and upgrade because supplying settings through Big Bang can
also change its generated integration configuration.

## Migrate plaintext values

Write a migrated copy while leaving the input unchanged:

```shell
scripts/migrate-values-3-to-4.sh --target 4 \
  --output values-4.x.yaml values.yaml
```

To replace one input, use `--in-place`. The command first creates
`values.yaml.bak` and refuses to overwrite an existing backup:

```shell
scripts/migrate-values-3-to-4.sh --target 4 --in-place values.yaml
```

### Consolidate layered plaintext values

Pass files in the same order used by Helm. The script composes them first,
applies later-file precedence, and writes one migrated document:

```shell
scripts/migrate-values-3-to-4.sh --target 4 \
  --output values-4.x.yaml \
  base.yaml environment.yaml secrets.yaml
```

Do not consolidate decrypted credentials into a file that will be committed.

### Keep values sources separate

Migrate the primary source normally:

```shell
scripts/migrate-values-3-to-4.sh --target 4 \
  --output values-4.x.yaml values.yaml
```

Migrate each secondary source with the omission option:

```shell
scripts/migrate-values-3-to-4.sh --target 4 \
  --omit-package-configuration \
  --output tests-4.x.yaml tests.yaml
```

Use this option only when another source in the same Big Bang release
supplies version `v1`.

## Migrate values in Kubernetes Secrets

### Decrypted Secret

Use `--secret-key` when a decrypted Kubernetes Secret stores values under
`stringData` or base64-encoded `data`:

```shell
scripts/migrate-values-3-to-4.sh --target 4 \
  --secret-key values.yaml \
  --output environment-4.x.yaml environment.yaml
```

Add `--omit-package-configuration` when the Secret is a secondary values
source. Do not use the plaintext command on a document that still contains
SOPS metadata.

### SOPS-encrypted Secret

The SOPS wrapper migrates and re-encrypts the selected values payload:

```shell
AWS_PROFILE=development \
  scripts/migrate-sops-values-3-to-4.sh --target 4 \
  --output environment-4.x.enc.yaml environment.enc.yaml
```

For a secondary encrypted source:

```shell
AWS_PROFILE=development \
  scripts/migrate-sops-values-3-to-4.sh --target 4 \
  --omit-package-configuration \
  --output secrets-4.x.enc.yaml secrets.enc.yaml
```

The embedded key defaults to `values.yaml`. See the
[SOPS command reference](package-values-migration-script.md#sops-migration-command)
for custom keys, output modes, and security behavior.

## Istio hardening changes

With `--target 4`, the migration removes the legacy `hardened` configuration model. The hardened
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

## Review and validate

Before committing migrated values:

1. Review every moved package and any expanded anchors.
2. Confirm exactly one separately stored source owns
   `packageConfiguration.version: v1`.
3. Confirm the sources remain in their original Helm or Flux order.
4. Run the migration on its generated output with the same target and relevant
   input-format options, writing to a different output file. The YAML values
   should be unchanged.
5. Render all migrated plaintext values in their effective order with a chart
   matching the selected target.

For one consolidated output:

```shell
helm template bigbang ./chart -f values-4.x.yaml >/dev/null
```

For separate plaintext sources:

```shell
helm template bigbang ./chart \
  -f values-4.x.yaml \
  -f tests-4.x.yaml \
  >/dev/null
```

For encrypted sources, decrypt and extract the values into a protected
temporary location for review and rendering. Never commit plaintext
credentials, private keys, license data, or production endpoints.

The migration is idempotent when rerun with the same options. The script also
expands and reports YAML anchors. Review the
[technical reference](package-values-migration-script.md) for precedence,
ordering, anchor handling, refusal conditions, and output guarantees.

Keep `packageConfiguration.version: v1` in the primary migrated configuration
when upgrading. Big Bang 4.x retains it as the unified package contract.

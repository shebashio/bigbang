# Migrating package values for Big Bang 4.0

Big Bang 4.0 moves built-in package configuration from top-level and
`addons.<name>` paths into `packages.<name>`. Starting with Big Bang 3.32, you
can adopt this structure before upgrading by setting:

```yaml
packageConfiguration:
  version: v1
```

The required `--target` option controls the rest of the migration. Use
`--target 3` to adopt only the unified package paths on Big Bang 3.32 or a later
3.x release. This retains the flat `bb-common` library values and legacy
hardening settings required by 3.x. Use `--target 4` when preparing values for
Big Bang 4.x; it also moves built-in package `istio`, `networkPolicies`, and
`routes` values beneath the `bb-common` subchart key and removes legacy
hardening after preserving its custom resources. Do not deploy target 4 output
to a 3.x release.

The script does not rewrite other deprecated Big Bang settings or unrelated
child-chart values. Follow the applicable release notes for those migrations.

Use this guide to choose and run a migration workflow. For complete option
semantics, safeguards, and troubleshooting, see the
[Package Values Migration Script Reference](package-values-migration-script.md).

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
| One plaintext values file | Run the plaintext script with the target matching the destination Big Bang major version. |
| Multiple plaintext files that can become one file | Pass every file in Helm order and write one consolidated output. |
| Values sources that must remain separate | Choose one primary source to own `packageConfiguration.version: v1`; use `--omit-package-configuration` on every secondary source. |
| Decrypted Kubernetes Secret | Use the plaintext script with `--secret-key`. |
| SOPS-encrypted Kubernetes Secret | Use the SOPS wrapper. |

For Big Bang 3.x, designate one source to own
`packageConfiguration.version: v1`, and always preserve the order in which
Helm or Flux applies values. Later sources override earlier sources.
Use the same target for every source in one deployment.

## Migrate plaintext values

Write a migrated copy while leaving the input unchanged:

```shell
scripts/migrate-values-3-to-4.sh \
  --target 4 \
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
scripts/migrate-values-3-to-4.sh \
  --target 4 \
  --output values-4.x.yaml \
  base.yaml environment.yaml secrets.yaml
```

Do not consolidate decrypted credentials into a file that will be committed.

### Keep values sources separate

Migrate the primary source normally:

```shell
scripts/migrate-values-3-to-4.sh \
  --target 4 \
  --output values-4.x.yaml values.yaml
```

Migrate each secondary source with the omission option:

```shell
scripts/migrate-values-3-to-4.sh \
  --target 4 \
  --omit-package-configuration \
  --output tests-4.x.yaml tests.yaml
```

Use this option only when another source in the same Big Bang 3.x release
supplies version `v1`.

## Migrate values in Kubernetes Secrets

### Decrypted Secret

Use `--secret-key` when a decrypted Kubernetes Secret stores values under
`stringData` or base64-encoded `data`:

```shell
scripts/migrate-values-3-to-4.sh \
  --target 4 \
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
  scripts/migrate-sops-values-3-to-4.sh \
  --target 4 \
  --output environment-4.x.enc.yaml environment.enc.yaml
```

For a secondary encrypted source:

```shell
AWS_PROFILE=development \
  scripts/migrate-sops-values-3-to-4.sh \
  --target 4 \
  --omit-package-configuration \
  --output secrets-4.x.enc.yaml secrets.enc.yaml
```

The embedded key defaults to `values.yaml`. See the
[SOPS command reference](package-values-migration-script.md#sops-migration-command)
for custom keys, output modes, and security behavior.

## `bb-common` and hardening changes for target 4

For target 4, the script moves each built-in package's flat `values.istio`,
`values.networkPolicies`, and `values.routes` configuration beneath
`values.bb-common`. If flat and already-nested values both exist, their maps are
recursively merged and the nested values take precedence. Unknown custom
packages are not rewritten because their `bb-common` consumption model is
owned by the package author.

Big Bang 4.x removes the legacy `hardened` configuration model. The hardened
posture is applied by default, and its individual behaviors are configured
directly through `bb-common` values. Target 4 makes these changes:

| Big Bang 3.x value | Big Bang 4.x result |
| --- | --- |
| `istiod.values.hardened` | Removed; there is no direct replacement because the hardened posture is the default. |
| `<package>.values.istio.hardened.enabled` | Removed; there is no direct replacement because the hardened posture is the default. |
| `<package>.values.istio.hardened.customServiceEntries` | Moved to `packages.<package>.values.bb-common.istio.serviceEntries.custom`. |
| `<package>.values.istio.hardened.customAuthorizationPolicies` | Moved to `packages.<package>.values.bb-common.istio.authorizationPolicies.custom`. |

When the destination already contains custom resources, migrated legacy entries
are prepended. The script reports non-istiod ServiceEntries for manual review
because they remain cluster-wide. If namespace-scoped egress is sufficient,
consider replacing them with package-scoped `bb-common.routes.outbound`
configuration.

## Review and validate

Before committing migrated values:

1. Review every moved package and any expanded anchors.
2. Confirm the selected target matches the chart that will consume the output.
3. Confirm exactly one separately stored source owns
   `packageConfiguration.version: v1`.
4. Confirm the sources remain in their original Helm or Flux order.
5. Rerun the same migration command with the same options; the output should be
   unchanged.
6. Render all migrated plaintext values in their effective order.

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

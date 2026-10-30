# Package Values Migration Script Reference

This page is the technical reference for the commands that migrate Big Bang
3.x package configuration to the unified Big Bang 4.x `packages` map. Start
with [Migrating Package Values for Big Bang 4.0](migrating-package-values-for-bb4.0.md)
to choose an end-to-end workflow. Use this page when selecting options,
reviewing exact behavior, or diagnosing a failure.

## Scope

Both targets move recognized built-in packages from their Big Bang 3.x
locations into `packages.<name>` and, by default, set:

```yaml
packageConfiguration:
  version: v1
```

Use `--omit-package-configuration` only for a secondary values source when
another source composed into the same Big Bang release supplies this contract.

Target 3 stops after the unified package-path migration, retaining flat
`bb-common` library values and legacy hardening for use with Big Bang 3.x.
Target 4 additionally nests `istio`, `networkPolicies`, and `routes` beneath
the `bb-common` subchart key, migrates legacy custom Istio resources, and
converts recognized legacy Istio hostname overrides to inbound routes. It also
removes legacy hardening. The commands do not rewrite other unrelated
deprecated settings or values passed through to child charts. Target 4 output
must not be deployed to Big Bang 3.x.

Two commands are available:

| Command | Use case |
| --- | --- |
| `scripts/migrate-values-3-to-4.sh` | Raw values files, parent Big Bang HelmReleases, package HelmRelease patches, or values embedded in a decrypted Kubernetes Secret |
| `scripts/migrate-sops-values-3-to-4.sh` | Values embedded in a SOPS-encrypted Kubernetes Secret |

## Requirements

Both commands require:

- Bash.
- [Mike Farah `yq`](https://github.com/mikefarah/yq) version 4.47.1 or newer.
  Version 4.47.1 is the minimum known compatible release because the migration
  requires `--yaml-fix-merge-anchor-to-spec`.
- `jq`.
- Standard command-line utilities including `base64`, `cmp`, `mktemp`, and
  `tr`.

The SOPS wrapper additionally requires:

- [`sops`](https://github.com/getsops/sops).
- Access to every master key required by the input document.
- Provider authentication in the environment, such as `AWS_PROFILE` for AWS
  KMS.

## Plaintext migration command

### Syntax

```text
migrate-values-3-to-4.sh --target {3|4} [OPTIONS] [INPUT ...]
```

### Options

| Option | Description |
| --- | --- |
| `-t VERSION`, `--target VERSION` | Required target Big Bang major version. Allowed values are `3` and `4`. |
| `-o FILE`, `--output FILE` | Write the migrated document to `FILE`. The output cannot resolve to an input file. |
| `-i`, `--in-place` | Replace one input after creating `INPUT.bak`. The command refuses to overwrite an existing backup. |
| `-k KEY`, `--secret-key KEY` | Treat one input as a decrypted Kubernetes Secret and migrate the values stored under `data[KEY]` or `stringData[KEY]`. |
| `--bigbang-helmrelease` | Migrate inline `spec.values` in one parent Big Bang HelmRelease or patch, preserving its wrapper and other fields. |
| `--helmrelease-patch FILE` | Convert a package HelmRelease patch into Big Bang values. Repeat for multiple files. Each file may contain multiple HelmRelease documents. |
| `--omit-package-configuration` | Remove `packageConfiguration` from the output. Use only for a secondary values source when another composed source supplies `packageConfiguration.version: v1`. |
| `-h`, `--help` | Print command help and exit. |

`--output` and `--in-place` are mutually exclusive. Without either option, the
migrated document is written to standard output and status messages are written
to standard error.

### Raw values files

Pass one raw values file to migrate it without changing the input:

```shell
scripts/migrate-values-3-to-4.sh \
  --target 4 \
  --output values-4.x.yaml values.yaml
```

Pass multiple values files in the same order supplied to Helm. The command
composes them using Helm values precedence, where later files win, and produces
one consolidated document:

```shell
scripts/migrate-values-3-to-4.sh \
  --target 4 \
  --output values-4.x.yaml \
  common.yaml environment.yaml secrets.yaml
```

Composition is important when legacy and canonical paths for the same package
occur in different layers. It preserves the rule that an existing canonical
`packages.<name>` value takes precedence over its legacy alias.

The final `packages` mapping follows first appearance in the effective composed
document. Recognized top-level packages, recognized entries under `addons`, and
existing `packages` entries retain that relative order as they are consolidated.
When more than one path configures the same package, its first appearance
determines its position while the normal canonical-value precedence still
determines its merged content.

### Legacy Istio hostname overrides

Target 4 converts recognized legacy host lists to:

```text
packages.<package>.values.bb-common.routes.inbound.<route>.hosts
```

Supported inputs include:

- Historical root/addon chart values, such as
  `tempo.values.istio.tempoQuery.hosts` and
  `addons.gitlab.values.istio.registry.hosts`.
- Canonical `packages.<package>.values.istio.<endpoint>.hosts`.
- Already-relocated
  `packages.<package>.values.bb-common.istio.<endpoint>.hosts`.
- Flat `istio.hosts` at package level or within chart values when the built-in
  package has one unambiguous inbound route. This includes the reported
  `packages.<package>.istio.hosts` form and root/addon equivalents. Historical
  package-level Istio controls were not a generic hostname passthrough; the
  migration accepts this form as a compatibility input.
- Named endpoint hosts at package level when the endpoint has an inventoried
  mapping.

For example, this hostname override from the release environment:

```yaml
tempo:
  values:
    istio:
      tempoQuery:
        hosts:
          - tempo.{{ .Values.domain }}
```

becomes:

```yaml
packageConfiguration:
  version: v1
packages:
  tempo:
    values:
      bb-common:
        routes:
          inbound:
            tempo-query:
              hosts:
                - tempo.{{ .Values.global.domain }}
```

For a package-level override, the corresponding input is:

```yaml
packageConfiguration:
  version: v1
packages:
  tempo:
    istio:
      hosts:
        - tempo.{{ .Values.domain }}
```

It produces the same inbound-route override. Other package controls, such as
`istio.injection`, remain at their existing locations.

Endpoint names are package-specific. For example, Monitoring's
`istio.prometheus.hosts` maps to `monitoring-prometheus.hosts`, while
`istio.alertmanager.hosts` maps to `monitoring-alertmanager.hosts`. GitLab's
`gitlab`, `registry`, and `pages` endpoints retain distinct host lists. The
[mapping inventory and input/output fixtures](../../tests/bats/migrate-values-3-to-4/fixtures/istio-hosts/README.md)
list all supported mappings and their historical sources.

Existing route hosts take precedence, including explicit empty lists or null
values. Existing flat `values.routes` are relocated before host conversion and
receive the same precedence. Otherwise, chart-value endpoint hosts take
precedence over flat chart-value hosts, followed by package-level endpoint
hosts and flat package-level hosts. Already-relocated chart values take
precedence over their flat aliases. File composition and package HelmRelease
patches happen before conversion, using their normal precedence.

The conversion preserves host order, duplicates, wildcards, and literal
`${variable}` placeholders. Since inbound routes render in the `bb-common`
subchart context, direct `{{ .Values.domain }}` expressions in legacy hosts
become `{{ .Values.global.domain }}` when the package passes the Big Bang
domain to the subchart. Whitespace-trimming markers are retained, and existing
`{{ .Values.global.domain }}` expressions remain unchanged. It
removes handled legacy host keys and containers emptied by that removal, while
preserving sibling settings and other route fields. Missing, empty-list, and
null legacy hosts do not create routes. Other legacy endpoint settings are
preserved and may need separate migration. Target 3 retains the 3.x hostname
configuration.

#### Manual hostname migration

A flat host list on a multi-endpoint package does not identify its intended
route. Custom packages, unknown endpoints, and endpoints with no supported
replacement also require manual selection. Unsupported Helm templates, such as
`{{ .Values.customDomain }}` or `{{ include "custom.host" . }}`, also require
manual translation because their meaning in the subchart cannot be inferred.
Domain templates also require manual migration for `argocd`, `kyvernoReporter`,
`mimir`, `minio`, and `sonarqube`: these umbrella integrations do not pass the
Big Bang domain as `bb-common`'s `global.domain`. For Argo CD, the value is
instead derived from the application's host.
When a package explicitly sets `values.domain` or `values.global.domain`,
legacy `{{ .Values.domain }}` hosts also require review: the old package domain
and the target subchart's global domain may differ. Compose all values sources
before migration when possible; otherwise, check for these overrides across
the separately migrated sources.
The script retains the whole host list and any lower-precedence legacy hosts
for that route rather than applying a potentially misleading fallback. These
hosts remain in the output,
and stderr reports the source path and the destination pattern, for example:

```text
Review: the following legacy Istio hosts require manual migration:
  packages.monitoring.istio.hosts: no unambiguous built-in endpoint mapping; hosts preserved. Set packages.monitoring.values.bb-common.routes.inbound.<route>.hosts explicitly, then remove the legacy hosts key.
```

This review diagnostic does not change the exit status: a successful command
can still produce values requiring manual work. Select the correct endpoint,
move the retained list to its inbound route, and remove the obsolete host key
before deployment. The script never copies one flat list to every endpoint.

Malformed recognized host lists or non-mapping destination ancestors cause a
nonzero exit before output is written. Nested ServiceEntry hosts, outbound
routes, and upstream ingress settings are not inbound hostname inputs and are
preserved.

### Separately stored values sources

Flux and Helm can compose values from several ConfigMaps, Secrets, or files
while those sources remain separate in Git. Designate one primary source to
own `packageConfiguration.version: v1`. Migrate every secondary source with
`--omit-package-configuration`. See the
[separate-sources workflow](migrating-package-values-for-bb4.0.md#keep-values-sources-separate)
for the command sequence.

The option removes the complete `packageConfiguration` block. It also treats
exact built-in names already under `packages` as intentional canonical package
configuration, which makes rerunning the same command on an omitted secondary
source idempotent.

Do not use this option for a standalone values document or when no other
source in the effective Big Bang 3.x values supplies version `v1`. Without the
discriminator, Big Bang 3.x interprets `packages` entries as custom packages.

### Parent Big Bang HelmReleases and values patches

Use `--bigbang-helmrelease` when a file targets the parent Big Bang release and
stores package configuration under `spec.values`. This includes Kustomize
patches organized into one file per package, such as:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: bigbang
spec:
  values:
    monitoring:
      enabled: true
    addons:
      argocd:
        enabled: true
```

Migrate a secondary patch while preserving its HelmRelease structure:

```shell
scripts/migrate-values-3-to-4.sh --target 4 \
  --bigbang-helmrelease --omit-package-configuration \
  --output monitoring-4.x.yaml monitoring.yaml
```

The output moves these entries to `spec.values.packages.monitoring` and
`spec.values.packages.argocd`. Existing canonical entries take precedence over
legacy entries, using the same merge and collision checks as raw values mode.
Custom package entries and unrelated values retain their existing behavior.

This mode preserves metadata, chart settings, `valuesFrom`, parent
`postRenderers`, and all other fields outside `spec.values`. Package-level
post-renderers move with their package configuration. Nested null values and
literal `${variable}` placeholders are preserved. Anchors are expanded using
the normal expansion checks; YAML formatting and comments may be normalized.

Without `--omit-package-configuration`, the command sets
`spec.values.packageConfiguration.version: v1`. For layered patches, designate
one primary source to supply that contract and use the omission option on
secondary patches. Migrate each patch independently so the Kustomize directory
structure and overlay order can remain intact:

```shell
scripts/migrate-values-3-to-4.sh --target 4 \
  --bigbang-helmrelease --omit-package-configuration \
  --in-place monitoring.yaml
```

In-place mode creates `monitoring.yaml.bak` and refuses to overwrite an existing
backup. A manifest without inline `spec.values` is preserved without adding a
values block or the package configuration discriminator. Referenced ConfigMaps
and Secrets are not resolved; migrate their values separately. Embedded patch
strings and JSON pointers are not rewritten.

The explicit option identifies the input as a parent release, so renamed parent
releases are supported. Inputs must contain exactly one decrypted Flux
HelmRelease document using API version `v2`, `v2beta2`, or `v2beta1`. This mode
cannot be combined with `--secret-key` or `--helmrelease-patch`.

JSON patch operation lists require manual review. Null deletions of legacy
package maps or package containers, and structural Kustomize directives inside
`spec.values`, also require manual migration. The command refuses these cases
before writing output rather than converting a deletion into an empty map.

### Package HelmRelease patches

Use `--helmrelease-patch` for customer overrides written as partial package
HelmRelease manifests. For example, `monitoring-patch.yaml`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: monitoring
  namespace: bigbang
spec:
  timeout: 20m
  upgrade:
    remediation:
      retries: 3
  values:
    upstream:
      prometheus:
        prometheusSpec:
          retention: 15d
```

Combine ordinary values and package patches:

```shell
scripts/migrate-values-3-to-4.sh --target 4 \
  --output values-4.x.yaml values.yaml \
  --helmrelease-patch monitoring-patch.yaml \
  --helmrelease-patch ek-patch.yaml
```

Ordinary values inputs are optional when migrating patches alone. The output
is a Big Bang values document, with `spec.values` under
`packages.<name>.values` and supported Flux settings under
`packages.<name>.flux`. Resource names map to canonical package keys, including
`ek` to `elasticsearchKibana` and `gitlab-runner` to `gitlabRunner`. The script
does not enable packages automatically.

All patches apply after the ordinary package-path migration, regardless of
where the options occur on the command line. Patches are composed in option order and
document order; later patches win. Maps merge recursively and lists replace
earlier lists. Omitted settings retain their earlier values.

Supported `spec` fields are `values`, `interval`, `timeout`, `install`,
`upgrade`, `rollback`, `uninstall`, `test`, `driftDetection`, `suspend`,
`maxHistory`, `persistentClient`, and `serviceAccountName`. Flux API versions
`v2`, `v2beta2`, and `v2beta1` are accepted. Each document must identify a
recognized built-in package by its HelmRelease `metadata.name`.

The script refuses unsupported fields rather than dropping them. In particular,
`valuesFrom` requires resolving external resources, and `dependsOn` or
`postRenderers` replacements can differ from chart-generated behavior. Chart
sources, extra metadata such as annotations, nulls, Kustomize directives, JSON
patches, custom packages, and dynamically named gateways require manual
migration. For a parent Big Bang HelmRelease, use
[`--bigbang-helmrelease`](#parent-big-bang-helmreleases-and-values-patches).
To convert child patches embedded in a parent post-renderer into values,
extract those child HelmRelease patches before using `--helmrelease-patch`.

Patch mode cannot be combined with `--in-place` or `--secret-key`. Inputs remain
unchanged; output paths cannot refer to any values or patch input. If any patch
fails validation, no migrated output is written. SOPS-encrypted patch manifests
must be decrypted separately before conversion.

Review the resulting values against the target release. Moving a child override
into Big Bang inputs lets umbrella templates account for that setting, which
can change generated integration configuration. Child-chart value names are
preserved except for the target 4 `bb-common`, legacy Istio hosts, and hardening migration.
Other child-chart schema changes require separate migration. Remove the original
package patches from the deployment when adopting the converted values, and
validate the resulting render and upgrade.

Package patch values also receive the selected target migration: target 3
retains flat library values, while target 4 nests `bb-common` values and
migrates legacy hardening after the patch overrides have been merged.

### Decrypted Kubernetes Secrets

Use `--secret-key` when the input is a decrypted Kubernetes Secret whose values
are stored as a YAML string:

```yaml
apiVersion: v1
kind: Secret
stringData:
  values.yaml: |
    monitoring:
      enabled: true
```

```shell
scripts/migrate-values-3-to-4.sh \
  --target 4 \
  --secret-key values.yaml \
  --output environment-4.x.yaml environment.yaml
```

The same option supports Kubernetes `data`, where the value must be valid
base64-encoded YAML:

```yaml
apiVersion: v1
kind: Secret
data:
  values.yaml: <base64-encoded YAML>
```

The command decodes the selected value, migrates it, restores its original
representation, and preserves the surrounding Secret fields. It rejects a key
that appears in both `data` and `stringData` because the intended source would
be ambiguous.

Secret mode accepts exactly one input. The input must already be decrypted and
must not contain top-level SOPS metadata.

## SOPS migration command

### Syntax

```text
migrate-sops-values-3-to-4.sh --target {3|4} [OPTIONS] INPUT
```

### Options

| Option | Description |
| --- | --- |
| `-t VERSION`, `--target VERSION` | Required target Big Bang major version. Allowed values are `3` and `4`; it is passed to the plaintext migration command. |
| `-o FILE`, `--output FILE` | Write the migrated SOPS-encrypted Secret to `FILE`. |
| `-i`, `--in-place` | Replace the encrypted input after creating an encrypted `INPUT.bak`. |
| `-k KEY`, `--values-key KEY` | Select the Secret key containing the values. The default is `values.yaml`. |
| `--omit-package-configuration` | Remove `packageConfiguration` from the encrypted values payload. Use only when another composed source supplies `packageConfiguration.version: v1`. |
| `-h`, `--help` | Print command help and exit. |

The wrapper accepts exactly one SOPS-encrypted Kubernetes Secret. It supports
both `stringData` and base64-encoded `data`.

### Write a separate encrypted result

```shell
AWS_PROFILE=development \
  scripts/migrate-sops-values-3-to-4.sh \
  --target 4 \
  --output environment-4.x.enc.yaml environment.enc.yaml
```

### Replace an encrypted input

```shell
AWS_PROFILE=development \
  scripts/migrate-sops-values-3-to-4.sh \
  --target 4 \
  --in-place environment.enc.yaml
```

### Select a different Secret key

```shell
AWS_PROFILE=development \
  scripts/migrate-sops-values-3-to-4.sh \
  --target 4 \
  --values-key bigbang.yaml \
  --output environment-4.x.enc.yaml environment.enc.yaml
```

### Migrate a secondary encrypted values source

```shell
AWS_PROFILE=development \
  scripts/migrate-sops-values-3-to-4.sh --target 4 \
  --omit-package-configuration \
  --output environment-4.x.enc.yaml environment.enc.yaml
```

The wrapper forwards the omission option to the plaintext migration and
verifies that the re-encrypted payload does not contain the block.

### SOPS processing model

The wrapper performs the following operations:

1. Creates a temporary directory with restrictive permissions.
2. Decrypts the input into that directory.
3. Calls `migrate-values-3-to-4.sh --target <target> --secret-key` on the decrypted Secret.
   The omission option is also forwarded when requested.
4. Uses the input document's existing SOPS metadata and master keys to update a
   temporary encrypted copy.
5. Decrypts the result and compares the complete Secret with the migrated
   plaintext document.
6. Writes the encrypted output only after verification succeeds.
7. Removes temporary plaintext on exit.

The wrapper does not pass plaintext values in command-line arguments and does
not write plaintext to standard output. Authentication is inherited from the
environment. Do not pass credentials as command options.

`SOPS_BIN` can identify an alternate `sops` executable:

```shell
SOPS_BIN=/opt/bin/sops \
  scripts/migrate-sops-values-3-to-4.sh \
  --target 4 \
  --output environment-4.x.enc.yaml environment.enc.yaml
```

The internal `migrate-sops-values-3-to-4-editor.sh` command is an implementation
detail and should not be invoked directly.

## YAML anchors and aliases

The commands automatically resolve YAML anchors, aliases, and merge keys before
migration. Merge keys use YAML-spec precedence, so an explicit mapping value
overrides a value from `<<` regardless of their order in the source document.
This matches Helm values behavior. Retaining aliases while moving their targets
between legacy and canonical package paths could produce an unclear or
misleading output document.

Before continuing, the plaintext command renders a canonical JSON view of the
resolved values both before and after expansion, sorts both with `jq`, and
requires those structures to match. If expansion changes the resolved
structure, the command fails without writing the result. The output contains
ordinary YAML values rather than anchors or aliases.

When anchors are detected, the command prints a warning and lists every expanded
anchor name. Use that list while reviewing the migrated output; the script does
not recreate anchors after migration.

Expansion can make the diff substantially larger because every alias becomes a
concrete value. Comments attached to anchor definitions can also move or be
removed by YAML serialization. Review the complete output, especially when
anchors represent credentials or package configuration shared across several
paths.

## Output and backup behavior

| Mode | Input changed | Output | Backup |
| --- | --- | --- | --- |
| No output option | No | Standard output | None |
| `--output FILE` | No | `FILE` | None |
| `--in-place` | Yes, after successful migration | Original path | `INPUT.bak` |

For the SOPS wrapper, standard output and output files remain encrypted. For
the plaintext command, they remain plaintext.

Both commands reject an output that is the input itself, including a symlink or
hardlink to the input. Use `--in-place` when replacement is intended.

## Layered values and precedence

The plaintext command can compose multiple raw values files, but Secret mode
and the SOPS wrapper accept one Secret at a time because they preserve the
Secret envelope.

Migrating layered Secrets independently can change precedence when one layer
uses a legacy path and another uses the canonical `packages.<name>` path. Before
changing the stored layers:

1. List every Helm or Flux values source in application order.
2. Decrypt and extract each values payload without committing plaintext.
3. Check whether the same package is configured through legacy and canonical
   paths across different layers.
4. If it is, pass the extracted values to the plaintext command in application
   order and review the consolidated result.

If the sources must remain separate, keep `packageConfiguration.version: v1`
in one primary values source and use `--omit-package-configuration` for every
secondary plaintext or encrypted source.

## Validation and refusal conditions

The commands stop without replacing the input when they encounter conditions
that cannot be migrated safely, including:

- Invalid YAML or a root value that is not a mapping.
- A missing target or a target other than `3` or `4`.
- Multiple YAML documents in ordinary values or Secret inputs. Files supplied
  with `--helmrelease-patch` may contain multiple HelmRelease documents.
- A semantic mismatch detected while automatically expanding YAML anchors and
  aliases.
- An unsupported `packageConfiguration.version`.
- A non-mapping `packages`, `addons`, or `packageConfiguration` value.
- A custom package name that conflicts with a built-in package identity.
- An existing unversioned custom package using an exact built-in name.
- A decrypted Secret key missing from both `data` and `stringData`.
- A Secret key present in both `data` and `stringData`.
- Malformed base64 under `data`.
- Missing SOPS metadata when using the SOPS wrapper.
- SOPS authentication, decryption, re-encryption, or verification failure.

The migration is idempotent. Running the same command on an already migrated
document makes no further package-path changes.

## Review and verification

Review the complete diff before adopting migrated values. The YAML processor
may normalize whitespace, list indentation, and blank lines outside the moved
package blocks.

For plaintext output, render or lint with the target Big Bang chart:

```shell
helm lint ./chart -f values-4.x.yaml
```

For SOPS output, confirm that it decrypts with the intended identity and review
the decrypted result in a protected temporary location. Do not commit decrypted
credentials, private keys, license material, or production endpoints.

## Troubleshooting

### `SOPS-encrypted input is not supported by this command`

The plaintext command detected top-level SOPS metadata. Use
`migrate-sops-values-3-to-4.sh` instead.

### `Secret does not contain values.yaml in data or stringData`

Confirm the key name. If the Secret uses another key, pass `--secret-key` to
the plaintext command or `--values-key` to the SOPS wrapper.

### `data.values.yaml is not valid base64`

Kubernetes `data` values must be base64 encoded. If the payload is raw YAML,
store it under `stringData` or correct the base64 value before migration.

### `expanding YAML anchors changed the resolved values structure`

The command detected that anchor expansion did not preserve the effective YAML
data and stopped before writing the result. Review the named anchors and expand
them manually before retrying. If the structures are equivalent and the error
persists, report the input shape as a migration-script defect without including
sensitive values.

### SOPS reports an authentication or access error

Authenticate to the provider that owns the master key and verify the identity
has decrypt access. For AWS KMS, confirm the active profile, account, Region,
KMS key policy, and any required encryption context.

### A backup already exists

The commands refuse to overwrite `INPUT.bak`. Review and relocate or remove the
existing backup before retrying. Ensure decrypted backups are protected and are
never committed.

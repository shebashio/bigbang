# Package Values Migration Script Reference

This page is the technical reference for the commands that migrate Big Bang
3.x package configuration to the unified Big Bang 4.x `packages` map. For the
upgrade workflow and configuration examples, see
[Migrating Package Values for Big Bang 4.0](migrating-package-values-for-bb4.0.md).

## Scope

The migration moves recognized built-in packages from their Big Bang 3.x
locations into `packages.<name>` and sets:

```yaml
packageConfiguration:
  version: v1
```

The commands do not rewrite unrelated deprecated Big Bang settings or values
passed through to child charts. Review the applicable release notes for those
changes.

Two commands are available:

| Command | Use case |
| --- | --- |
| `scripts/migrate-values-3-to-4.sh` | Raw values files or values embedded in a decrypted Kubernetes Secret |
| `scripts/migrate-sops-values-3-to-4.sh` | Values embedded in a SOPS-encrypted Kubernetes Secret |

## Requirements

Both commands require:

- Bash.
- [Mike Farah `yq`](https://github.com/mikefarah/yq) version 4.
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
migrate-values-3-to-4.sh [OPTIONS] INPUT [INPUT ...]
```

### Options

| Option | Description |
| --- | --- |
| `-o FILE`, `--output FILE` | Write the migrated document to `FILE`. The output cannot resolve to an input file. |
| `-i`, `--in-place` | Replace one input after creating `INPUT.bak`. The command refuses to overwrite an existing backup. |
| `-k KEY`, `--secret-key KEY` | Treat one input as a decrypted Kubernetes Secret and migrate the values stored under `data[KEY]` or `stringData[KEY]`. |
| `-h`, `--help` | Print command help and exit. |

`--output` and `--in-place` are mutually exclusive. Without either option, the
migrated document is written to standard output and status messages are written
to standard error.

### Raw values files

Pass one raw values file to migrate it without changing the input:

```shell
scripts/migrate-values-3-to-4.sh \
  --output values-4.x.yaml values.yaml
```

Pass multiple values files in the same order supplied to Helm. The command
composes them using Helm values precedence, where later files win, and produces
one consolidated document:

```shell
scripts/migrate-values-3-to-4.sh \
  --output values-4.x.yaml \
  common.yaml environment.yaml secrets.yaml
```

Composition is important when legacy and canonical paths for the same package
occur in different layers. It preserves the rule that an existing canonical
`packages.<name>` value takes precedence over its legacy alias.

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
migrate-sops-values-3-to-4.sh [OPTIONS] INPUT
```

### Options

| Option | Description |
| --- | --- |
| `-o FILE`, `--output FILE` | Write the migrated SOPS-encrypted Secret to `FILE`. |
| `-i`, `--in-place` | Replace the encrypted input after creating an encrypted `INPUT.bak`. |
| `-k KEY`, `--values-key KEY` | Select the Secret key containing the values. The default is `values.yaml`. |
| `-h`, `--help` | Print command help and exit. |

The wrapper accepts exactly one SOPS-encrypted Kubernetes Secret. It supports
both `stringData` and base64-encoded `data`.

### Write a separate encrypted result

```shell
AWS_PROFILE=development \
  scripts/migrate-sops-values-3-to-4.sh \
  --output environment-4.x.enc.yaml environment.enc.yaml
```

### Replace an encrypted input

```shell
AWS_PROFILE=development \
  scripts/migrate-sops-values-3-to-4.sh \
  --in-place environment.enc.yaml
```

### Select a different Secret key

```shell
AWS_PROFILE=development \
  scripts/migrate-sops-values-3-to-4.sh \
  --values-key bigbang.yaml \
  --output environment-4.x.enc.yaml environment.enc.yaml
```

### SOPS processing model

The wrapper performs the following operations:

1. Creates a temporary directory with restrictive permissions.
2. Decrypts the input into that directory.
3. Calls `migrate-values-3-to-4.sh --secret-key` on the decrypted Secret.
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
  --output environment-4.x.enc.yaml environment.enc.yaml
```

The internal `migrate-sops-values-3-to-4-editor.sh` command is an implementation
detail and should not be invoked directly.

## YAML anchors and aliases

The commands automatically resolve YAML anchors, aliases, and merge keys before
migration. Retaining aliases while moving their targets between legacy and
canonical package paths could produce an unclear or misleading output document.

Before continuing, the plaintext command renders a canonical JSON view of the
resolved values both before and after expansion and requires those structures
to match. If expansion changes the resolved structure, the command fails without
writing the result. The output contains ordinary YAML values rather than anchors
or aliases.

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

## Validation and refusal conditions

The commands stop without replacing the input when they encounter conditions
that cannot be migrated safely, including:

- Invalid YAML or a root value that is not a mapping.
- Multiple YAML documents.
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
